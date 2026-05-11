<script setup lang="ts">
import { ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import axios from 'axios';
import { MapPin, Save, ArrowLeft, Loader2 } from 'lucide-vue-next';

const router = useRouter();
const loading = ref(false);
const searchingCep = ref(false);

const form = ref({
  street: '',
  number: '',
  city: '',
  state: '',
  zip: '',
  latitude: '',
  longitude: ''
});

// Watch CEP for auto-fill
watch(() => form.value.zip, async (newCep) => {
  const cleanCep = newCep.replace(/\D/g, '');
  if (cleanCep.length === 8) {
    searchingCep.value = true;
    try {
      const res = await axios.get(`https://viacep.com.br/ws/${cleanCep}/json/`);
      if (!res.data.erro) {
        form.value.street = res.data.logradouro;
        form.value.city = res.data.localidade;
        form.value.state = res.data.uf;
      }
    } catch (err) {
      console.error('Error fetching CEP:', err);
    } finally {
      searchingCep.value = false;
    }
  }
});

// Auto-fetch Lat/Lon when address is complete
const fetchGeocode = async () => {
  if (!form.value.street || !form.value.number || !form.value.city) return;
  
  try {
    const query = `${form.value.street}, ${form.value.number}, ${form.value.city}, ${form.value.state}, Brasil`;
    const res = await axios.get(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=1`);
    
    if (res.data && res.data.length > 0) {
      form.value.latitude = res.data[0].lat;
      form.value.longitude = res.data[0].lon;
    }
  } catch (err) {
    console.error('Geocoding error:', err);
  }
};

const submitForm = async () => {
  loading.value = true;
  try {
    // Final attempt at geocoding if lat/lon are missing
    if (!form.value.latitude || !form.value.longitude) {
      await fetchGeocode();
    }

    await axios.post('http://localhost:3000/addresses', {
      address: {
        ...form.value,
        latitude: parseFloat(form.value.latitude),
        longitude: parseFloat(form.value.longitude)
      }
    });
    alert('Endereço cadastrado com sucesso!');
    router.push('/');
  } catch (err) {
    console.error('Error saving address:', err);
    alert('Erro ao salvar endereço.');
  } finally {
    loading.value = false;
  }
};
</script>

<template>
  <div class="container-small">
    <header class="header">
      <button @click="router.push('/')" class="btn-text">
        <ArrowLeft :size="20" /> Voltar
      </button>
      <h1 class="title">Novo Endereço</h1>
    </header>

    <div class="card">
      <form @submit.prevent="submitForm">
        <div class="form-grid">
          <div class="form-group">
            <label>CEP</label>
            <div class="relative">
              <input v-model="form.zip" type="text" required placeholder="00000-000" maxlength="9" />
              <Loader2 v-if="searchingCep" class="animate-spin absolute right-3 top-3 text-primary" :size="18" />
            </div>
          </div>

          <div class="form-group">
            <label>Número</label>
            <input v-model="form.number" type="text" required placeholder="1000" @blur="fetchGeocode" />
          </div>

          <div class="form-group full">
            <label>Rua</label>
            <input v-model="form.street" type="text" required placeholder="Preenchido via CEP" :readonly="!!form.street && form.zip.length > 0" />
          </div>

          <div class="form-group">
            <label>Cidade</label>
            <input v-model="form.city" type="text" required placeholder="São Paulo" readonly />
          </div>

          <div class="form-group">
            <label>Estado</label>
            <input v-model="form.state" type="text" required placeholder="SP" maxlength="2" readonly />
          </div>

          <div class="form-group">
            <label>Latitude</label>
            <input v-model="form.latitude" type="number" step="any" required placeholder="Auto-calculado" />
          </div>

          <div class="form-group">
            <label>Longitude</label>
            <input v-model="form.longitude" type="number" step="any" required placeholder="Auto-calculado" />
          </div>
        </div>

        <button type="submit" class="btn btn-primary w-full mt-6" :disabled="loading || searchingCep">
          <Save :size="20" /> {{ loading ? 'Salvando...' : 'Cadastrar Endereço' }}
        </button>
      </form>
    </div>
  </div>
</template>

<style scoped>
.container-small {
  max-width: 600px;
  margin: 0 auto;
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
}

.form-group.full {
  grid-column: span 2;
}

.form-group label {
  display: block;
  font-size: 0.875rem;
  font-weight: 500;
  margin-bottom: 0.5rem;
  color: var(--text-muted);
}

.relative { position: relative; }

input {
  width: 100%;
  padding: 0.75rem;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--border);
  border-radius: 8px;
  color: white;
  transition: border-color 0.2s;
}

input[readonly] {
  background: rgba(255, 255, 255, 0.02);
  color: var(--text-muted);
  cursor: not-allowed;
}

input:focus:not([readonly]) {
  outline: none;
  border-color: var(--primary);
}

.btn-text {
  background: none;
  border: none;
  color: var(--text-muted);
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
  font-weight: 600;
}

.btn-text:hover {
  color: var(--text);
}

.animate-spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.mt-6 { margin-top: 1.5rem; }
.w-full { width: 100%; }
</style>
