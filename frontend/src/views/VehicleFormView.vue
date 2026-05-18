<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import axios from 'axios';
import { Save, ArrowLeft } from 'lucide-vue-next';

const router = useRouter();
const loading = ref(false);

const form = ref({
  plate: '',
  model: '',
  capacity: 0
});

const handlePlateInput = (event: Event) => {
  const target = event.target as HTMLInputElement;
  // Remove caracteres especiais, mantenha apenas letras e números
  let raw = target.value.toUpperCase().replace(/[^A-Z0-9]/g, '');
  let formatted = '';

  for (let i = 0; i < raw.length; i++) {
    const char = raw[i];
    if (i < 3) {
      if (/[A-Z]/.test(char)) formatted += char;
    } else if (i === 3) {
      if (/[0-9]/.test(char)) formatted += char;
    } else if (i === 4) {
      if (/[A-Z0-9]/.test(char)) formatted += char;
    } else if (i < 7) {
      if (/[0-9]/.test(char)) formatted += char;
    }
  }

  // Add hyphen for display
  if (formatted.length > 3) {
    formatted = formatted.slice(0, 3) + '-' + formatted.slice(3);
  }

  form.value.plate = formatted;
};

const submitForm = async () => {
  // Validate complete plate
  if (form.value.plate.length !== 8) {
    alert('A placa precisa estar no formato correto (Ex: ABC-1234 ou ABC-1A23)');
    return;
  }

  loading.value = true;
  try {
    const payload = {
      ...form.value,
      plate: form.value.plate.replace('-', '')
    };
    
    await axios.post('http://localhost:3000/vehicles', {
      vehicle: payload
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
            <input :value="form.plate" @input="handlePlateInput" type="text" required placeholder="Ex: ABC-1234" maxlength="8" />
          </div>
          
          <div class="form-group full">
            <label>Modelo</label>
            <input v-model="form.model" type="text" required placeholder="Ex: Mercedes Sprinter" />
          </div>

          <div class="form-group full">
            <label>Capacidade (Pacotes)</label>
            <input v-model="form.capacity" type="number" required placeholder="10" min="1" />
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
  position: fixed;
  top: 2rem;
  left: calc(var(--sidebar-width) + 2rem);
  z-index: 50;
}

.btn-text:hover {
  color: var(--text);
}

.title {
  margin-left: 6rem;
}

.mt-6 { margin-top: 1.5rem; }
.w-full { width: 100%; }
</style>
