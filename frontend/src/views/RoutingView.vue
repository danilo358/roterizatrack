<script setup lang="ts">
import { ref, onMounted, computed, watch, nextTick } from 'vue';
import axios from 'axios';
import { Truck, MapPin, Navigation, CheckCircle, Map as MapIcon, Eye, EyeOff, Trash2, Check, X, AlertCircle, Play, Zap, ListOrdered, RefreshCw, Plus, TrendingUp } from 'lucide-vue-next';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { v4 as uuidv4 } from 'uuid';
import ConfirmationModal from '../components/ConfirmationModal.vue';
import { theme } from '../store/theme';

// Haversine Distance Formula (Returns KM)
const calculateDistance = (lat1: number, lon1: number, lat2: number, lon2: number) => {
  const R = 6371; // Radius of the earth in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

interface Address {
  id: string;
  latitude: number;
  longitude: number;
  street: string;
  number?: string;
  city?: string;
  state?: string;
  zip?: string;
  status?: string;
  vehicle_id?: string | null;
  route_id?: string | null;
  sequence_number?: number | null;
}

interface Vehicle {
  id: string;
  plate: string;
  capacity: number;
  model: string;
}

const addresses = ref<Address[]>([]);
const vehicles = ref<Vehicle[]>([]);
const selectedVehicleId = ref<string | null>(null);
const selectedAddressIds = ref<string[]>([]);
const loading = ref(false);
const suggestedRoute = ref<Address[] | null>(null);
const totalDistance = ref<number | null>(null);
const routeGeometry = ref<any | null>(null);

// Visibility Control
const visibleRoutes = ref<Set<string>>(new Set());
const showUnassigned = ref(true);
const routesGeometryCache = ref<Record<string, any>>({});

// Simulation State
const simulatingRoutes = ref<Set<string>>(new Set());
const simulatedStopStatuses = ref<Record<string, string>>({}); // stopId -> status text
const vehicleMarkers = ref<Record<string, L.Marker>>({});

const MANAGEMENT_URL = 'http://localhost:3000';
const ROUTING_URL = 'http://localhost:3001';

// Map variables
let map: L.Map | null = null;
const mapContainer = ref<HTMLElement | null>(null);
const markers = ref<L.Marker[]>([]);
const routeLine = ref<L.Polyline | null>(null);

const markersGroup = L.layerGroup();
const routesGroup = L.layerGroup();

const routeColors = [
  '#6366f1', '#ec4899', '#10b981', '#f59e0b', '#3b82f6', '#8b5cf6', '#ef4444'
];

// Modal state
const modalShow = ref(false);
const modalConfig = ref({ title: '', message: '', onConfirm: () => {} });

const openModal = (title: string, message: string, onConfirm: () => void) => {
  modalConfig.value = { title, message, onConfirm };
  modalShow.value = true;
};

const handleModalConfirm = () => {
  modalShow.value = false;
  modalConfig.value.onConfirm();
};

let currentTileLayer: L.TileLayer | null = null;

const initMap = () => {
  if (map) return;
  map = L.map(mapContainer.value!).setView([-23.55052, -46.633308], 12);
  updateMapTiles();
  markersGroup.addTo(map);
  routesGroup.addTo(map);

  // Fix for map not rendering in grid layouts
  setTimeout(() => {
    map?.invalidateSize();
  }, 100);
};

const updateMapTiles = () => {
  if (!map) return;
  if (currentTileLayer) map.removeLayer(currentTileLayer);
  
  const isDark = theme.value === 'dark';
  const tileUrl = isDark 
    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
    : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
    
  currentTileLayer = L.tileLayer(tileUrl, {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
    subdomains: 'abcd',
    maxZoom: 20
  }).addTo(map);
};

// Watch for theme changes to update map style
watch(theme, () => {
  updateMapTiles();
});

const updateMarkers = () => {
  if (!map) return;
  markersGroup.clearLayers();
  routesGroup.clearLayers();

  const allPoints: L.LatLngExpression[] = [];

  const addMarker = (addr: Address, color: string, label?: string) => {
    const icon = L.divIcon({
      className: 'custom-div-icon',
      html: `<div class="marker-pin" style="background: ${color}"><span>${label || ''}</span></div>`,
      iconSize: [30, 42],
      iconAnchor: [15, 42]
    });
    
    const marker = L.marker([Number(addr.latitude), Number(addr.longitude)], { icon })
      .addTo(markersGroup)
      .on('click', () => {
        toggleAddress(addr.id);
      });
    
    if (label) marker.bindTooltip(`Parada ${label}`, { permanent: false, direction: 'top' });
    else marker.bindTooltip(addr.street, { permanent: false, direction: 'top' });
    
    allPoints.push([Number(addr.latitude), Number(addr.longitude)]);
  };

  if (showUnassigned.value) {
    unassignedAddresses.value.forEach((addr) => {
      const selectedIdx = selectedAddressIds.value.indexOf(addr.id);
      const isSelected = selectedIdx > -1;
      const color = isSelected ? '#6366f1' : '#94a3b8';
      const label = isSelected ? (selectedIdx + 1).toString() : '';
      addMarker(addr, color, label);
    });
  }

  const grouped = groupedRoutes.value;
  let colorIdx = 0;
  Object.keys(grouped).forEach(vId => {
    grouped[vId].forEach((route) => {
      const routeKey = `${vId}-${route.route_id}`;
      if (visibleRoutes.value.has(routeKey)) {
        const color = routeColors[colorIdx % routeColors.length]!;
        route.addresses.forEach((a, idx) => addMarker(a, color, (idx + 1).toString()));
        
        // Draw Route Line
        const latLngs = route.addresses.map(a => [Number(a.latitude), Number(a.longitude)] as L.LatLngExpression);
        
        // Try to use cached geometry if available, otherwise draw straight lines
        if (routesGeometryCache.value[routeKey]) {
          L.geoJSON(routesGeometryCache.value[routeKey], { style: { color, weight: 5, opacity: 0.6 } }).addTo(routesGroup);
        } else if (latLngs.length > 1) {
          L.polyline(latLngs, { color, weight: 4, opacity: 0.5, dashArray: '5, 10' }).addTo(routesGroup);
          // Async fetch and cache geometry
          fetchAndCacheGeometry(routeKey, route.addresses);
        }
        
        colorIdx++;
      }
    });
  });

  if (selectedAddressIds.value.length > 1) {
    const manualLatLngs = selectedAddressIds.value
      .map(id => addresses.value.find(a => a.id === id))
      .filter(a => !!a)
      .map(a => [Number(a!.latitude), Number(a!.longitude)] as L.LatLngExpression);
    
    L.polyline(manualLatLngs, { color: '#6366f1', weight: 3, opacity: 0.4, dashArray: '5, 10' }).addTo(routesGroup);
  }

  if (suggestedRoute.value && routeGeometry.value) {
    L.geoJSON(routeGeometry.value, { style: { color: '#6366f1', weight: 6 } }).addTo(routesGroup);
    suggestedRoute.value.forEach((a, idx) => addMarker(a, '#6366f1', (idx + 1).toString()));
  }

  if (allPoints.length > 0) {
    const bounds = L.latLngBounds(allPoints);
    map.fitBounds(bounds, { padding: [50, 50] });
  }
};

const fetchAndCacheGeometry = async (key: string, stops: Address[]) => {
  if (routesGeometryCache.value[key] || stops.length < 2) return;
  try {
    const coords = stops.map(s => `${s.longitude},${s.latitude}`).join(';');
    const osrmUrl = `http://router.project-osrm.org/route/v1/driving/${coords}?overview=full&geometries=geojson`;
    const res = await axios.get(osrmUrl);
    if (res.data.routes?.length > 0) {
      routesGeometryCache.value[key] = res.data.routes[0].geometry;
      updateMarkers(); // Re-render with new geometry
    }
  } catch (e) { console.error('Cache geometry error:', e); }
};

const fetchAll = async () => {
  try {
    const [addrRes, vehRes] = await Promise.all([
      axios.get(`${MANAGEMENT_URL}/addresses`),
      axios.get(`${MANAGEMENT_URL}/vehicles`)
    ]);
    addresses.value = addrRes.data;
    vehicles.value = vehRes.data;
    
    // Auto-show new routes if any
    addresses.value.forEach(a => {
      if (a.vehicle_id && a.route_id) {
        visibleRoutes.value.add(`${a.vehicle_id}-${a.route_id}`);
      }
    });

    nextTick(() => {
      initMap();
      updateMarkers();
    });
  } catch (err) {
    console.error('Error fetching data:', err);
  }
};

onMounted(fetchAll);

// Watchers to update map
watch([addresses, suggestedRoute, selectedAddressIds, visibleRoutes, showUnassigned], () => {
  updateMarkers();
}, { deep: true });

const toggleRouteVisibility = (vId: string, rId: string) => {
  const key = `${vId}-${rId}`;
  if (visibleRoutes.value.has(key)) visibleRoutes.value.delete(key);
  else visibleRoutes.value.add(key);
};

const toggleAllVisible = () => {
  const allShown = Object.keys(groupedRoutes.value).every(vId => 
    groupedRoutes.value[vId].every(r => visibleRoutes.value.has(`${vId}-${r.route_id}`))
  ) && showUnassigned.value;

  if (allShown) {
    visibleRoutes.value.clear();
    showUnassigned.value = false;
  } else {
    Object.keys(groupedRoutes.value).forEach(vId => {
      groupedRoutes.value[vId].forEach(r => visibleRoutes.value.add(`${vId}-${r.route_id}`));
    });
    showUnassigned.value = true;
  }
};

const isEverythingVisible = computed(() => {
  const routesCount = Object.values(groupedRoutes.value).flat().length;
  return (visibleRoutes.value.size >= routesCount) && showUnassigned.value;
});

const toggleAddress = (id: string) => {
  const index = selectedAddressIds.value.indexOf(id);
  if (index > -1) {
    selectedAddressIds.value.splice(index, 1);
  } else {
    selectedAddressIds.value.push(id);
  }
};

const isOverCapacity = computed(() => {
  if (!selectedVehicleId.value) return false;
  const vehicle = vehicles.value.find(v => v.id === selectedVehicleId.value);
  return vehicle ? selectedAddressIds.value.length > vehicle.capacity : false;
});

const calculateRoute = async (optimized: boolean = false) => {
  if (!selectedVehicleId.value || selectedAddressIds.value.length === 0) return;
  
  if (isOverCapacity.value) {
    alert('Capacidade do veículo excedida!');
    return;
  }

  loading.value = true;
  try {
    const res = await axios.post(`${ROUTING_URL}/rotas/calcular`, {
      veiculo_id: selectedVehicleId.value,
      endereco_ids: selectedAddressIds.value,
      optimized
    });
    suggestedRoute.value = res.data.ordered_stops;
    totalDistance.value = res.data.total_distance_km;
    routeGeometry.value = res.data.geometry;
  } catch (err) {
    console.error('Error calculating route:', err);
  } finally {
    loading.value = false;
  }
};

const assignRoute = async () => {
  if (!selectedVehicleId.value || !suggestedRoute.value) return;

  loading.value = true;
  const newRouteId = uuidv4();
  try {
    await axios.post(`${ROUTING_URL}/rotas/atribuir`, {
      veiculo_id: selectedVehicleId.value,
      endereco_ids: suggestedRoute.value.map(a => a.id),
      route_id: newRouteId,
      total_distance_km: totalDistance.value || 0
    });
    // Cache the geometry we just used so it stays on map
    routesGeometryCache.value[`${selectedVehicleId.value}-${newRouteId}`] = routeGeometry.value;
    
    suggestedRoute.value = null;
    totalDistance.value = null;
    routeGeometry.value = null;
    selectedAddressIds.value = [];
    await fetchAll();
  } catch (err) {
    console.error('Error assigning route:', err);
  } finally {
    loading.value = false;
  }
};

const instantCompleteRoute = async (vId: string, rId: string) => {
  loading.value = true;
  try {
    const routeAddrs = addresses.value.filter(a => a.vehicle_id === vId && a.route_id === rId);
    await Promise.all(routeAddrs.map(a => 
      axios.patch(`${MANAGEMENT_URL}/addresses/${a.id}`, {
        address: { status: 'concluido' }
      })
    ));
    await fetchAll();
  } catch (err) { console.error(err); } finally { loading.value = false; }
};

const cancelRoute = async (vId: string, rId: string) => {
  openModal(
    'Cancelar Rota',
    'Deseja cancelar esta rota? Entregas já concluídas serão mantidas no histórico.',
    async () => {
      loading.value = true;
      try {
        const routeAddrs = addresses.value.filter(a => a.vehicle_id === vId && a.route_id === rId);
        await Promise.all(routeAddrs.map(a => {
          if (a.status !== 'concluido') {
            return axios.patch(`${MANAGEMENT_URL}/addresses/${a.id}`, {
              address: { status: 'pendente', vehicle_id: null, route_id: null, sequence_number: null }
            });
          }
          return Promise.resolve();
        }));
        await fetchAll();
      } catch (err) { console.error(err); } finally { loading.value = false; }
    }
  );
};

const completeRoute = async (vId: string, rId: string) => {
  openModal(
    'Concluir Rota',
    'Deseja marcar todas as paradas desta rota como concluídas?',
    async () => {
      loading.value = true;
      try {
        const routeAddrs = addresses.value.filter(a => a.vehicle_id === vId && a.route_id === rId);
        await Promise.all(routeAddrs.map(a => 
          axios.patch(`${MANAGEMENT_URL}/addresses/${a.id}`, {
            address: { status: 'concluido' }
          })
        ));
        await fetchAll();
      } catch (err) { console.error(err); } finally { loading.value = false; }
    }
  );
};

const updateStopStatus = async (addr: Address, status: string) => {
  loading.value = true;
  try {
    const payload: any = { status };
    if (status === 'pendente') {
      payload.vehicle_id = null;
      payload.route_id = null;
      payload.sequence_number = null;
    }
    await axios.patch(`${MANAGEMENT_URL}/addresses/${addr.id}`, { address: payload });
    await fetchAll();
  } catch (err) { console.error(err); } finally { loading.value = false; }
};

const groupedRoutes = computed(() => {
  const groups: Record<string, { route_id: string, addresses: Address[], status: string }[]> = {};
  vehicles.value.forEach(v => {
    const vehicleAddresses = addresses.value.filter(a => a.vehicle_id === v.id && a.route_id);
    const routesMap: Record<string, Address[]> = {};
    vehicleAddresses.forEach(a => {
      if (!routesMap[a.route_id!]) routesMap[a.route_id!] = [];
      routesMap[a.route_id!]!.push(a);
    });
    groups[v.id] = Object.entries(routesMap).map(([id, addrs]) => {
      const allDone = addrs.every(a => a.status === 'concluido');
      return { 
        route_id: id, 
        addresses: addrs.sort((a, b) => (a.sequence_number || 0) - (b.sequence_number || 0)),
        status: allDone ? 'concluido' : 'em rota'
      };
    });
  });
  return groups;
});

const startSimulation = async (vId: string, rId: string) => {
  const routeKey = `${vId}-${rId}`;
  if (simulatingRoutes.value.has(routeKey)) return;

  const routeData = groupedRoutes.value[vId]?.find(r => r.route_id === rId);
  if (!routeData || !routesGeometryCache.value[routeKey]) {
    alert('Geometria da rota não disponível para simulação.');
    return;
  }

  simulatingRoutes.value.add(routeKey);
  const stops = routeData.addresses;
  const geometry = routesGeometryCache.value[routeKey];
  const coords = geometry.coordinates; // OSRM returns [lon, lat]

  // Pre-calculate arrival index for each stop (closest point on the line)
  const stopArrivalIndices = stops.map(stop => {
    let closestIdx = 0;
    let minDict = Infinity;
    coords.forEach(([lon, lat]: [number, number], idx: number) => {
      const d = calculateDistance(lat, lon, Number(stop.latitude), Number(stop.longitude));
      if (d < minDict) {
        minDict = d;
        closestIdx = idx;
      }
    });
    return { stopId: stop.id, arrivalIdx: closestIdx };
  });

  // Initialize statuses
  stops.forEach(s => simulatedStopStatuses.value[s.id] = 'Aguardando');
  if (stops[0]) simulatedStopStatuses.value[stops[0].id] = 'A caminho';

  // Create vehicle marker
  const vehicleIcon = L.divIcon({
    className: 'vehicle-marker',
    html: '<div class="moving-truck">🚚</div>',
    iconSize: [40, 40],
    iconAnchor: [20, 20]
  });

  const marker = L.marker([coords[0][1], coords[0][0]], { icon: vehicleIcon }).addTo(map!);
  vehicleMarkers.value[routeKey] = marker;

  let currentCoordIdx = 0;
  let currentStopIdx = 0;

  const animate = async () => {
    if (currentCoordIdx >= coords.length || !simulatingRoutes.value.has(routeKey)) {
      simulatingRoutes.value.delete(routeKey);
      marker.remove();
      return;
    }

    const [lon, lat] = coords[currentCoordIdx];
    marker.setLatLng([lat, lon]);

    // Index-based logic: Check if we reached the pre-calculated stop point
    const target = stopArrivalIndices[currentStopIdx];
    if (target) {
      if (currentCoordIdx >= target.arrivalIdx) {
        const currentStop = stops[currentStopIdx];
        simulatedStopStatuses.value[currentStop.id] = 'Concluido';
        await updateStopStatus(currentStop, 'concluido');
        
        currentStopIdx++;
        if (stops[currentStopIdx]) {
          simulatedStopStatuses.value[stops[currentStopIdx].id] = 'A caminho';
        }
      } else if (target.arrivalIdx - currentCoordIdx < 15) {
        // 15 coordinate steps before the stop
        simulatedStopStatuses.value[stops[currentStopIdx].id] = 'Proxima Parada';
      }
    }

    currentCoordIdx++;
    setTimeout(() => requestAnimationFrame(animate), 50);
  };

  requestAnimationFrame(animate);
};

const unassignedAddresses = computed(() => addresses.value.filter(a => !a.route_id && a.status === 'pendente'));

const canCalculate = computed(() => {
  return selectedVehicleId.value && selectedAddressIds.value.length > 0 && !loading.value && !isOverCapacity.value;
});

const currentlySimulatedRoute = computed(() => {
  if (simulatingRoutes.value.size === 0) return null;
  const routeId = Array.from(simulatingRoutes.value)[0];
  for (const vId in groupedRoutes.value) {
    const route = groupedRoutes.value[vId].find(r => r.route_id === routeId);
    if (route) return { ...route, vehicle_plate: vehicles.value.find(v => v.id === vId)?.plate };
  }
  return null;
});

const getVehiclePlate = (id: string) => {
  return vehicles.value.find(v => v.id === id)?.plate || 'N/A';
};
</script>

<template>
  <div class="container">
    <header class="header">
      <div class="flex items-center gap-3">
        <h1 class="title">RoterizaTrack</h1>
        <span class="status-badge bg-primary/10 text-primary !text-[9px]">LIVE OPS</span>
      </div>
      <button class="btn btn-secondary !py-1 !px-3 text-[10px]" @click="fetchAll" :disabled="loading">
        <RefreshCw :size="12" :class="{ 'animate-spin': loading }" />
      </button>
    </header>

    <div class="toolbar">
      <div class="flex items-center gap-2">
        <button class="btn btn-secondary !py-1 !px-4 text-[10px]" :disabled="!canCalculate" @click="calculateRoute(false)">
          <Navigation :size="12" /> Ordem Manual
        </button>
        <button class="btn btn-primary !py-1 !px-4 text-[10px]" :disabled="!canCalculate" @click="calculateRoute(true)">
          <Zap :size="12" /> Melhor Caminho
        </button>
        
        <div v-if="totalDistance" class="flex flex-col items-start ml-2 pl-4 border-l border-border">
          <span class="text-[9px] font-bold uppercase text-muted">Total Estimado</span>
          <span class="text-sm font-bold text-primary">{{ totalDistance.toFixed(1) }} km</span>
        </div>
      </div>

      <div class="flex items-center gap-4 ml-auto">
        <span v-if="isOverCapacity" class="text-[11px] text-error font-bold flex items-center gap-1 bg-error/10 px-2 py-1 rounded">
          <AlertCircle :size="12" /> Veículo tem capacidade de apenas {{ vehicles.find(v => v.id === selectedVehicleId)?.capacity || 0 }} pacotes
        </span>
        <button v-if="totalDistance" class="btn btn-primary !py-1 !px-6 text-[10px] !bg-success !border-success" @click="assignRoute" :disabled="loading">
          <Check :size="12" /> Confirmar Rota
        </button>
      </div>
    </div>

    <div class="dashboard-grid">
      <!-- Coluna Principal: Mapa -->
      <main class="card !p-0 overflow-hidden map-area">
        <div ref="mapContainer" class="map-container"></div>
      </main>

      <!-- Coluna Lateral -->
      <div class="side-panels">
        <!-- 1. Pontos Disponíveis -->
        <aside class="card">
          <h2 class="section-title"><MapPin :size="14" /> Pendentes</h2>
          <div class="item-list">
            <div v-for="addr in unassignedAddresses" 
              :key="addr.id" 
              class="item" 
              :class="{ 'selected-success': selectedAddressIds.includes(addr.id) }"
              @click="toggleAddress(addr.id)">
              <div class="flex items-center gap-2">
                <div v-if="selectedAddressIds.includes(addr.id)" class="bg-success text-white w-4 h-4 rounded-full flex items-center justify-center text-[9px] font-bold shrink-0">
                  {{ selectedAddressIds.indexOf(addr.id) + 1 }}
                </div>
                <MapPin v-else :size="14" class="text-muted shrink-0" />
                <p class="font-bold truncate text-[11px]">{{ addr.street }}, {{ addr.number }}</p>
              </div>
            </div>
          </div>
        </aside>

        <!-- 2. Seleção de Veículo -->
        <aside class="card">
          <h2 class="section-title"><Truck :size="14" /> Veículo da Rota</h2>
          <div class="item-list">
            <div v-for="v in vehicles" :key="v.id" class="item !p-2" :class="{ 'selected-success': selectedVehicleId === v.id }" @click="selectedVehicleId = v.id">
              <div class="flex items-center gap-2">
                <Truck :size="14" :class="selectedVehicleId === v.id ? 'text-success' : 'text-muted'" />
                <span class="text-[10px] font-bold" :class="selectedVehicleId === v.id ? 'text-success' : ''">{{ v.plate }} ({{ v.model }})</span>
              </div>
            </div>
          </div>
        </aside>
      </div>

    </div>

    <!-- Monitor de Operações (Lista Grande Embaixo) -->
    <div class="monitor-section">
      <template v-for="v in vehicles" :key="v.id">
        <div v-for="(route, idx) in groupedRoutes[v.id]" :key="route.route_id" class="card mb-4">
          <div class="flex justify-between items-center mb-4">
            <h2 class="section-title mb-0 flex items-center gap-2">
              <Truck :size="18" class="text-primary" /> 
              Veículo em Rota: <span class="text-primary">{{ v.plate }} ({{ v.model }})</span>
            </h2>
            <div class="flex gap-2 items-center">
              <span v-if="simulatingRoutes.has(route.route_id)" class="status-badge bg-primary/20 text-primary !text-[10px] mr-2">Simulação Ativa</span>
              <button class="stop-action-btn success" title="Concluir Toda a Rota" @click="instantCompleteRoute(v.id, route.route_id)"><CheckCircle :size="14" /></button>
              <button class="stop-action-btn primary" title="Iniciar Simulação" @click="startSimulation(v.id, route.route_id)"><Play :size="14" /></button>
              <button class="stop-action-btn error" title="Cancelar Rota" @click="cancelRoute(v.id, route.route_id)"><Trash2 :size="14" /></button>
            </div>
          </div>
          
          <div class="flex flex-col mt-2">
            <div v-for="(stop, stopIdx) in route.addresses" :key="stop.id" 
              class="monitor-row" 
              :class="{ 
                'bg-success/5': stop.status === 'concluido',
                'bg-primary/5': simulatedStopStatuses[stop.id] === 'A Caminho'
              }">
              <div class="flex items-center gap-3">
                <div class="w-5 h-5 rounded-full bg-primary flex items-center justify-center text-[10px] font-bold text-white shrink-0">
                  {{ stopIdx + 1 }}
                </div>
                <p class="font-bold text-xs truncate" :title="`${stop.street}, ${stop.number}`">{{ stop.street }}, {{ stop.number }}</p>
              </div>
              <div class="flex items-center gap-3">
                <span v-if="simulatedStopStatuses[stop.id]" :class="['sim-status-badge', simulatedStopStatuses[stop.id]?.toLowerCase().replace(' ', '-')]">
                  {{ simulatedStopStatuses[stop.id] }}
                </span>
                <span v-else-if="stop.status === 'concluido'" class="sim-status-badge concluido">Entregue</span>
                <span v-else class="sim-status-badge aguardando">Aguardando</span>
                
                <button v-if="stop.status !== 'concluido'" @click="updateStopStatus(stop, 'concluido')" class="stop-action-btn success" title="Marcar como Entregue">
                  <CheckCircle :size="14" />
                </button>
              </div>
            </div>
          </div>

        </div>
      </template>
    </div>





    <ConfirmationModal :show="modalShow" :title="modalConfig.title" :message="modalConfig.message" @confirm="handleModalConfirm" @cancel="modalShow = false" />
  </div>
</template>

<style scoped>
.map-container { 
  width: 100%; 
  height: 100%; 
  border-radius: var(--radius); 
  z-index: 1; 
}
.route-group { border-radius: var(--radius); overflow: hidden; }
.bg-surface-light { background: rgba(255, 255, 255, 0.05); }

.stop-number { 
  width: 16px; 
  height: 16px; 
  background: var(--primary); 
  border-radius: 50%; 
  display: flex; 
  align-items: center; 
  justify-content: center; 
  font-size: 8px; 
  font-weight: bold; 
  color: white;
  flex-shrink: 0;
}

.stop-action-btn {
  width: 24px;
  height: 24px;
  border-radius: 6px;
  border: 1px solid var(--border);
  background: rgba(255, 255, 255, 0.03);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
  color: var(--text-muted);
}

.stop-action-btn:hover { background: rgba(255, 255, 255, 0.1); }
.stop-action-btn.primary:hover { color: var(--primary); border-color: var(--primary); }
.stop-action-btn.error:hover { color: var(--error); border-color: var(--error); }

.sim-status-badge {
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 8px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.sim-status-badge.concluido { background: rgba(16, 185, 129, 0.1); color: #10b981; }
.sim-status-badge.a-caminho { background: rgba(59, 130, 246, 0.1); color: #3b82f6; animation: pulse 2s infinite; }
.sim-status-badge.proxima-parada { background: rgba(245, 158, 11, 0.1); color: #f59e0b; }
.sim-status-badge.aguardando { background: rgba(255, 255, 255, 0.05); color: var(--text-muted); }

@keyframes pulse {
  0% { opacity: 1; }
  50% { opacity: 0.5; }
  100% { opacity: 1; }
}

:deep(.marker-pin) { 
  width: 24px; 
  height: 24px; 
  border-radius: 50% 50% 50% 0; 
  position: absolute; 
  transform: rotate(-45deg) translateY(-12px); 
  left: 50%; 
  top: 50%; 
  margin: -12px 0 0 -12px; 
  display: flex; 
  align-items: center; 
  justify-content: center; 
  color: white; 
  font-size: 10px; 
  font-weight: bold; 
  border: 1px solid white; 
}

:deep(.marker-pin > span) {
  transform: rotate(45deg);
}

.moving-truck {
  font-size: 20px;
  filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));
}
</style>
