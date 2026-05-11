<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import axios from 'axios';
import { BarChart3, Truck, Package, Navigation, TrendingUp } from 'lucide-vue-next';

const vehicles = ref<any[]>([]);
const addresses = ref<any[]>([]);
const metrics = ref<any[]>([]);
const loading = ref(true);

const MANAGEMENT_URL = 'http://localhost:3000';
const ROUTING_URL = 'http://localhost:3001';

const fetchData = async () => {
  try {
    const [vRes, aRes, mRes] = await Promise.all([
      axios.get(`${MANAGEMENT_URL}/vehicles`),
      axios.get(`${MANAGEMENT_URL}/addresses`),
      axios.get(`${ROUTING_URL}/metrics`)
    ]);
    vehicles.value = vRes.data;
    addresses.value = aRes.data;
    metrics.value = mRes.data;
  } catch (err) {
    console.error('Error fetching metrics:', err);
  } finally {
    loading.value = false;
  }
};

onMounted(fetchData);

const stats = computed(() => {
  const totalPackages = addresses.value.length;
  const delivered = addresses.value.filter(a => a.status === 'concluido').length;
  const inTransit = addresses.value.filter(a => a.status === 'em rota').length;
  const totalKm = metrics.value.reduce((acc, m) => acc + Number(m.total_km), 0);
  
  return {
    totalPackages,
    delivered,
    inTransit,
    totalKm: totalKm.toFixed(2),
    completionRate: totalPackages ? ((delivered / totalPackages) * 100).toFixed(1) : 0
  };
});

const vehicleStats = computed(() => {
  return vehicles.value.map(v => {
    const vMetrics = metrics.value.find(m => m.vehicle_id === v.id) || { total_km: 0, total_routes: 0 };
    const vAddresses = addresses.value.filter(a => a.vehicle_id === v.id);
    const vDelivered = vAddresses.filter(a => a.status === 'concluido').length;
    
    return {
      ...v,
      totalKm: Number(vMetrics.total_km).toFixed(2),
      totalRoutes: vMetrics.total_routes,
      delivered: vDelivered,
      pending: vAddresses.length - vDelivered
    };
  });
});
</script>

<template>
  <div class="reports-container">
    <div class="reports-header">
      <div>
        <h1>Relatórios de Desempenho</h1>
        <p>Visão detalhada da sua operação logística e frota.</p>
      </div>
      <button class="btn btn-secondary" @click="fetchData">
        <TrendingUp :size="18" /> Atualizar Dados
      </button>
    </div>

    <!-- Summary Cards -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon icon-primary"><Navigation :size="24" /></div>
        <div class="stat-info">
          <label>Distância Total</label>
          <div class="value">{{ stats.totalKm }} <small>km</small></div>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon icon-success"><CheckCircle :size="24" /></div>
        <div class="stat-info">
          <label>Entregas Sucesso</label>
          <div class="value">{{ stats.delivered }}</div>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon icon-warning"><Truck :size="24" /></div>
        <div class="stat-info">
          <label>Frota em Rota</label>
          <div class="value">{{ stats.inTransit }}</div>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon icon-indigo"><TrendingUp :size="24" /></div>
        <div class="stat-info">
          <label>Eficiência Geral</label>
          <div class="value">{{ stats.completionRate }}%</div>
        </div>
      </div>
    </div>

    <!-- Vehicle Table -->
    <div class="data-card">
      <div class="card-header">
        <h2>Desempenho por Veículo</h2>
        <span class="badge">{{ vehicleStats.length }} veículos ativos</span>
      </div>
      
      <div class="table-wrapper">
        <table class="report-table">
          <thead>
            <tr>
              <th>Veículo / Placa</th>
              <th>Produtividade</th>
              <th>Quilometragem</th>
              <th class="text-center">Rotas</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="v in vehicleStats" :key="v.id">
              <td>
                <div class="vehicle-cell">
                  <div class="v-icon"><Truck :size="16" /></div>
                  <div>
                    <p class="v-model">{{ v.model }}</p>
                    <p class="v-plate">{{ v.plate }}</p>
                  </div>
                </div>
              </td>
              <td>
                <div class="progress-container">
                  <div class="progress-info">
                    <span>{{ v.delivered }}</span> / {{ v.delivered + v.pending }}
                  </div>
                  <div class="progress-bar">
                    <div 
                      class="progress-fill" 
                      :style="{ width: v.delivered + v.pending > 0 ? (v.delivered / (v.delivered + v.pending) * 100) + '%' : '0%' }"
                    ></div>
                  </div>
                </div>
              </td>
              <td><span class="font-bold">{{ v.totalKm }}</span> <small class="text-muted">km</small></td>
              <td class="text-center"><span class="route-count">{{ v.totalRoutes }}</span></td>
              <td>
                <span :class="['status-badge', v.pending > 0 ? 'bg-warning' : (v.delivered > 0 ? 'bg-success' : 'bg-muted')]">
                  {{ v.pending > 0 ? 'Em Operação' : (v.delivered > 0 ? 'Finalizado' : 'Disponível') }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<style scoped>
.reports-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 1rem;
}

.reports-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2.5rem;
}

.reports-header h1 {
  font-size: 1.8rem;
  font-weight: 800;
  margin: 0;
}

.reports-header p {
  color: var(--text-muted);
  font-size: 0.9rem;
  margin-top: 0.25rem;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2.5rem;
}

.stat-card {
  background: var(--surface);
  border: 1px solid var(--border);
  padding: 1.5rem;
  border-radius: 20px;
  display: flex;
  align-items: center;
  gap: 1.25rem;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
}

.stat-icon {
  width: 52px;
  height: 52px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.icon-primary { background: rgba(99, 102, 241, 0.1); color: var(--primary); }
.icon-success { background: rgba(16, 185, 129, 0.1); color: var(--success); }
.icon-warning { background: rgba(245, 158, 11, 0.1); color: var(--warning); }
.icon-indigo { background: rgba(99, 102, 241, 0.1); color: #818cf8; }

.stat-info label {
  display: block;
  font-size: 0.7rem;
  font-weight: 800;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 0.2rem;
}

.stat-info .value {
  font-size: 1.5rem;
  font-weight: 700;
}

.data-card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 24px;
  overflow: hidden;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
}

.card-header {
  padding: 1.5rem 2rem;
  border-bottom: 1px solid var(--border);
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: rgba(255, 255, 255, 0.02);
}

.card-header h2 {
  font-size: 1.1rem;
  font-weight: 700;
  margin: 0;
}

.badge {
  font-size: 0.7rem;
  font-weight: 700;
  color: var(--text-muted);
  text-transform: uppercase;
}

.table-wrapper {
  overflow-x: auto;
}

.report-table {
  width: 100%;
  border-collapse: collapse;
}

.report-table th {
  padding: 1rem 2rem;
  background: rgba(255, 255, 255, 0.03);
  font-size: 0.7rem;
  font-weight: 800;
  color: var(--text-muted);
  text-transform: uppercase;
  text-align: left;
  border-bottom: 1px solid var(--border);
}

.report-table td {
  padding: 1.25rem 2rem;
  border-bottom: 1px solid var(--border);
}

.vehicle-cell {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.v-icon {
  width: 36px;
  height: 36px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--primary);
}

.v-model { font-weight: 700; font-size: 0.9rem; margin: 0; }
.v-plate { font-size: 0.75rem; color: var(--text-muted); margin: 0; font-family: monospace; }

.progress-container {
  width: 140px;
}

.progress-info {
  font-size: 0.75rem;
  margin-bottom: 0.4rem;
  color: var(--text-muted);
}

.progress-info span { color: var(--text); font-weight: 700; }

.progress-bar {
  height: 6px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 10px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: var(--success);
  border-radius: 10px;
}

.route-count {
  background: rgba(255, 255, 255, 0.05);
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: 700;
}

.status-badge {
  padding: 0.35rem 0.75rem;
  border-radius: 8px;
  font-size: 0.65rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.bg-warning { background: rgba(245, 158, 11, 0.1); color: var(--warning); }
.bg-success { background: rgba(16, 185, 129, 0.1); color: var(--success); }
.bg-muted { background: rgba(255, 255, 255, 0.05); color: var(--text-muted); }

.text-center { text-align: center !important; }
</style>
