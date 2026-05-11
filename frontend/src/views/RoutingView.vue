<script setup lang="ts">
import { ref, onMounted, computed, watch, nextTick } from 'vue';
import axios from 'axios';
import { Truck, MapPin, Navigation, CheckCircle, Map as MapIcon, Eye, EyeOff, Trash2, Check, X, AlertCircle, Play } from 'lucide-vue-next';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { v4 as uuidv4 } from 'uuid';
import ConfirmationModal from '../components/ConfirmationModal.vue';

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

const initMap = () => {
  if (map) return;
  map = L.map(mapContainer.value!).setView([-23.55052, -46.633308], 12);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);
  markersGroup.addTo(map);
  routesGroup.addTo(map);
};

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
    L.marker([Number(addr.latitude), Number(addr.longitude)], { icon })
      .addTo(markersGroup)
      .bindPopup(`<b>${addr.street}</b>`);
    allPoints.push([Number(addr.latitude), Number(addr.longitude)]);
  };

  if (showUnassigned.value) {
    unassignedAddresses.value.forEach(a => {
      const isSelected = selectedAddressIds.value.includes(a.id);
      addMarker(a, isSelected ? '#f59e0b' : '#94a3b8');
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

const getVehiclePlate = (id: string) => {
  return vehicles.value.find(v => v.id === id)?.plate || 'N/A';
};
</script>

<template>
  <div class="grid">
    <!-- Left Column: Address Management -->
    <section>
      <div class="card mb-6">
        <h2 class="section-title mb-4"><MapIcon :size="20" /> Mapa de Entregas</h2>
        <div ref="mapContainer" class="map-container"></div>
      </div>

      <div class="card">
        <div class="flex justify-between items-center mb-6">
          <h2 class="section-title mb-0"><MapPin :size="20" /> Gerenciamento</h2>
          <div class="flex gap-2">
            <button class="btn-icon" @click="toggleAllVisible" :title="isEverythingVisible ? 'Esconder Todos' : 'Mostrar Todos'">
              <EyeOff v-if="isEverythingVisible" :size="20" />
              <Eye v-else :size="20" />
            </button>
          </div>
        </div>
        
        <!-- Unassigned Section -->
        <div class="mb-8">
          <div class="flex justify-between items-center mb-3 mt-4">
            <h3 class="text-sm font-bold uppercase text-muted">Aguardando Rota</h3>
            <button class="btn-icon" @click="showUnassigned = !showUnassigned">
              <Eye v-if="showUnassigned" :size="18" />
              <EyeOff v-else :size="18" />
            </button>
          </div>
          <div class="item-list" v-if="showUnassigned">
            <div v-for="addr in unassignedAddresses" :key="addr.id" class="item"
              :class="{ 'selected': selectedAddressIds.includes(addr.id) }"
              @click="toggleAddress(addr.id)">
              <div class="item-header">
                <div>
                  <strong>{{ addr.street }}, {{ addr.number }}</strong>
                  <p class="text-sm text-muted">{{ addr.city }} - {{ addr.state }}</p>
                </div>
                <span class="status-badge status-pendente">pendente</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Vehicle Routes -->
        <div v-for="v in vehicles" :key="v.id" class="mb-8">
          <h3 class="text-xs font-bold uppercase text-primary mb-3">{{ v.plate }} - {{ v.model }}</h3>
          <div v-for="(route, idx) in groupedRoutes[v.id]" :key="route.route_id" class="route-group mb-4" :class="{ 'opacity-60': route.status === 'concluido' }">
            <div class="flex justify-between items-center p-3 bg-surface-light rounded-t-lg border border-border">
              <span class="text-xs font-bold uppercase flex items-center gap-2">
                <CheckCircle v-if="route.status === 'concluido'" :size="14" class="text-success" />
                Rota {{ idx + 1 }} &nbsp; | &nbsp; {{ route.addresses.length }} paradas
              </span>
              <div class="flex gap-2">
                <button v-if="route.status !== 'concluido'" class="stop-action-btn success" @click="completeRoute(v.id, route.route_id)" title="Concluir Rota">
                  <CheckCircle :size="16" />
                </button>
                <button v-if="route.status !== 'concluido'" class="stop-action-btn primary" @click="startSimulation(v.id, route.route_id)" title="Simular Entrega">
                  <Play :size="16" />
                </button>
                <button class="stop-action-btn error" @click="cancelRoute(v.id, route.route_id)" title="Cancelar Rota">
                  <Trash2 :size="16" />
                </button>
                <button class="stop-action-btn" @click="toggleRouteVisibility(v.id, route.route_id)">
                  <Eye v-if="visibleRoutes.has(`${v.id}-${route.route_id}`)" :size="16" />
                  <EyeOff v-else :size="16" />
                </button>
              </div>
            </div>
            <div class="item-list-compact border-x border-b border-border rounded-b-lg p-2" v-if="visibleRoutes.has(`${v.id}-${route.route_id}`)">
              <div v-for="(addr, aIdx) in route.addresses" :key="addr.id" class="item-compact flex justify-between items-center">
                <div class="flex items-center gap-2">
                  <span class="stop-number">{{ aIdx + 1 }}</span>
                  <div :class="{ 'line-through text-muted': addr.status === 'concluido' }">
                    <span class="text-xs">{{ addr.street }}, {{ addr.number }}</span>
                    <span v-if="simulatedStopStatuses[addr.id]" :class="['sim-status-badge', simulatedStopStatuses[addr.id]?.toLowerCase().replace(' ', '-')]">
                      {{ simulatedStopStatuses[addr.id] }}
                    </span>
                  </div>
                </div>
                <div class="flex gap-2">
                  <button v-if="addr.status !== 'concluido'" class="stop-action-btn success" @click="updateStopStatus(addr, 'concluido')" title="Concluir Parada">
                    <Check :size="14" />
                  </button>
                  <button v-if="addr.status !== 'concluido'" class="stop-action-btn error" @click="updateStopStatus(addr, 'pendente')" title="Remover da Rota">
                    <X :size="14" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <div v-if="addresses.length === 0" class="empty-state">
          Nenhum endereço cadastrado.
        </div>
      </div>
    </section>

    <!-- Right Column: Routing Controls -->
    <aside>
      <div class="card">
        <h2 class="section-title"><Navigation :size="20" /> Criar Rota</h2>
        
        <div class="mb-6">
          <label class="block text-sm font-medium mb-2">Selecionar Veículo</label>
          <div class="item-list">
            <div 
              v-for="v in vehicles" 
              :key="v.id"
              class="item"
              :class="{ 'selected': selectedVehicleId === v.id }"
              @click="selectedVehicleId = v.id"
            >
              <div class="flex items-center gap-3">
                <Truck :size="20" class="text-primary" />
                <div>
                  <strong>{{ v.plate }}</strong>
                  <p class="text-xs text-muted">{{ v.model }} (Cap: {{ v.capacity }})</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="mb-6">
          <div v-if="isOverCapacity" class="error-badge mb-4">
            Atenção: Você selecionou {{ selectedAddressIds.length }} endereços, mas este veículo suporta apenas {{ vehicles.find(v => v.id === selectedVehicleId)?.capacity }} paradas.
          </div>
          <div class="flex gap-2">
            <button 
              class="btn btn-secondary w-full" 
              :disabled="!selectedVehicleId || selectedAddressIds.length === 0 || loading || isOverCapacity"
              @click="calculateRoute(false)"
            >
              Lat/Lon
            </button>
            <button 
              class="btn btn-primary w-full" 
              :disabled="!selectedVehicleId || selectedAddressIds.length === 0 || loading || isOverCapacity"
              @click="calculateRoute(true)"
            >
              Melhor Rota
            </button>
          </div>
        </div>

        <!-- Suggested Route Display -->
        <div v-if="suggestedRoute" class="mt-8 pt-8 border-t border-border">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-md font-bold flex items-center gap-2">
              <CheckCircle :size="18" class="text-success" /> Rota Sugerida
            </h3>
            <span class="status-badge status-em-rota" v-if="totalDistance">
              {{ totalDistance.toFixed(2) }} km
            </span>
          </div>
          <div class="item-list mb-6">
            <div v-for="(stop, index) in suggestedRoute" :key="stop.id" class="flex gap-3">
              <div class="flex flex-col items-center">
                <div class="w-6 h-6 rounded-full bg-primary flex items-center justify-center text-xs font-bold">
                  {{ index + 1 }}
                </div>
                <div v-if="index < suggestedRoute.length - 1" class="w-0.5 h-full bg-border my-1"></div>
              </div>
              <div class="flex-1 pb-4">
                <p class="text-sm font-semibold">{{ stop.street }}</p>
              </div>
            </div>
          </div>
          
          <button 
            class="btn btn-primary w-full mt-4" 
            @click="assignRoute"
            :disabled="loading"
          >
            <Truck :size="18" /> Confirmar Atribuição
          </button>
        </div>
      </div>
    </aside>
    <!-- Confirmation Modal -->
    <ConfirmationModal 
      :show="modalShow"
      :title="modalConfig.title"
      :message="modalConfig.message"
      @confirm="handleModalConfirm"
      @cancel="modalShow = false"
    />
  </div>
</template>

<style scoped>
.map-container { height: 450px; width: 100%; border-radius: var(--radius); z-index: 1; }
.route-group { border-radius: var(--radius); overflow: hidden; }
.bg-surface-light { background: rgba(255, 255, 255, 0.05); }
.item-list-compact { display: flex; flex-direction: column; gap: 0.25rem; background: rgba(0, 0, 0, 0.2); }
.item-compact { display: flex; align-items: center; gap: 0.75rem; padding: 0.5rem; border-bottom: 1px solid rgba(255, 255, 255, 0.05); }
.stop-number { width: 18px; height: 18px; background: var(--primary); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 10px; font-weight: bold; }
.btn-icon { background: none; border: none; color: var(--text-muted); cursor: pointer; padding: 4px; border-radius: 4px; }
.btn-icon:hover { background: rgba(255, 255, 255, 0.1); color: var(--text); }
.btn-sm { padding: 0.4rem 0.8rem; font-size: 0.75rem; }
:deep(.marker-pin) { width: 30px; height: 30px; border-radius: 50% 50% 50% 0; position: absolute; transform: rotate(-45deg) translateY(-15px); left: 50%; top: 50%; margin: -15px 0 0 -15px; display: flex; align-items: center; justify-content: center; color: white; font-size: 12px; font-weight: bold; border: 2px solid white; transition: all 0.3s; }
:deep(.marker-pin:hover) { transform: rotate(-45deg) translateY(-20px) scale(1.2); z-index: 1000; }

/* Fix for Leaflet rotation of labels */
:deep(.marker-pin > span) {
  transform: rotate(45deg);
  z-index: 10;
}

.mb-6 { margin-bottom: 1.5rem; }
.mb-8 { margin-bottom: 2rem; }
.mt-4 { margin-top: 1rem; }
.mt-8 { margin-top: 2rem; }
.pt-8 { padding-top: 2rem; }
.border-t { border-top: 1px solid var(--border); }
.w-full { width: 100%; }
.flex { display: flex; }
.items-center { align-items: center; }
.justify-center { justify-content: center; }
.gap-2 { gap: 0.5rem; }
.gap-3 { gap: 0.75rem; }
.gap-4 { gap: 1rem; }
.flex-col { flex-direction: column; }
.flex-1 { flex: 1; }
.text-sm { font-size: 0.875rem; }
.text-xs { font-size: 0.75rem; }
.font-bold { font-weight: 700; }
.font-semibold { font-weight: 600; }
.uppercase { text-transform: uppercase; }
.text-primary { color: var(--primary); }
.text-muted { color: var(--text-muted); }
.text-success { color: var(--success); }
.opacity-50 { opacity: 0.5; }
.stop-action-btn {
  width: 28px;
  height: 28px;
  border-radius: 8px;
  border: 1px solid var(--border);
  background: rgba(255, 255, 255, 0.03);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
  color: var(--text-muted);
}

.stop-action-btn.success:hover {
  background: rgba(16, 185, 129, 0.1);
  border-color: rgba(16, 185, 129, 0.3);
  color: var(--success);
}

.stop-action-btn.error:hover {
  background: rgba(239, 68, 68, 0.1);
  border-color: rgba(239, 68, 68, 0.3);
  color: var(--error);
}
.sim-status-badge {
  font-size: 9px;
  font-weight: 800;
  text-transform: uppercase;
  padding: 1px 4px;
  border-radius: 4px;
  margin-left: 6px;
}

.sim-status-badge.aguardando { background: rgba(148, 163, 184, 0.1); color: #94a3b8; }
.sim-status-badge.a-caminho { background: rgba(59, 130, 246, 0.1); color: #3b82f6; animation: pulse-blue 2s infinite; }
.sim-status-badge.proxima-parada { background: rgba(245, 158, 11, 0.1); color: #f59e0b; }
.sim-status-badge.concluido { background: rgba(16, 185, 129, 0.1); color: #10b981; }

@keyframes pulse-blue {
  0% { opacity: 0.6; }
  50% { opacity: 1; }
  100% { opacity: 0.6; }
}

.moving-truck {
  font-size: 24px;
  filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));
  transition: transform 0.1s linear;
}

.stop-action-btn.primary:hover {
  background: rgba(99, 102, 241, 0.1);
  border-color: rgba(99, 102, 241, 0.3);
  color: var(--primary);
}
</style>
