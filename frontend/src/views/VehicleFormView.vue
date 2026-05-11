<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import axios from 'axios';
import { Truck, Save, ArrowLeft } from 'lucide-vue-next';

const router = useRouter();
const loading = ref(false);

const form = ref({
  plate: '',
  model: '',
  capacity: 0
});

const submitForm = async () => {
  loading.value = true;
  try {
    await axios.post('http://localhost:3000/vehicles', {
      vehicle: form.value
    });
    alert('Veículo cadastrado com sucesso!');
    router.push('/');
  } catch (err) {
    console.error('Error saving vehicle:', err);
    alert('Erro ao salvar veículo.');
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
      <h1 class="title">Novo Veículo</h1>
    </header>

    <div class="card">
      <form @submit.prevent="submitForm">
        <div class="form-grid">
          <div class="form-group full">
            <label>Placa</label>
            <input v-model="form.plate" type="text" required placeholder="Ex: ABC-1234" />
          </div>
          
          <div class="form-group full">
            <label>Modelo</label>
            <input v-model="form.model" type="text" required placeholder="Ex: Mercedes Sprinter" />
          </div>

          <div class="form-group full">
            <label>Capacidade (Pacotes)</label>
            <input v-model="form.capacity" type="number" required placeholder="10" />
          </div>
        </div>

        <button type="submit" class="btn btn-primary w-full mt-6" :disabled="loading">
          <Save :size="20" /> {{ loading ? 'Salvando...' : 'Cadastrar Veículo' }}
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
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-group label {
  display: block;
  font-size: 0.875rem;
  font-weight: 500;
  margin-bottom: 0.5rem;
  color: var(--text-muted);
}

input {
  width: 100%;
  padding: 0.75rem;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--border);
  border-radius: 8px;
  color: white;
  transition: border-color 0.2s;
}

input:focus {
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

.mt-6 { margin-top: 1.5rem; }
.w-full { width: 100%; }
</style>
