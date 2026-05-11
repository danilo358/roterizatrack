<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import axios from 'axios';
import { LogIn, Lock, Mail, Loader2 } from 'lucide-vue-next';

const router = useRouter();
const email = ref('admin@trackland.com');
const password = ref('password123');
const loading = ref(false);
const error = ref('');

const handleLogin = async () => {
  loading.value = true;
  error.value = '';
  try {
    const res = await axios.post('http://localhost:3000/login', {
      email: email.value,
      password: password.value
    });
    
    localStorage.setItem('user', JSON.stringify(res.data));
    router.push('/');
  } catch (err: any) {
    error.value = err.response?.data?.error || 'Erro ao fazer login';
  } finally {
    loading.value = false;
  }
};
</script>

<template>
  <div class="login-container">
    <div class="login-card">
      <div class="login-header">
        <div class="logo">
          <Truck :size="40" class="text-primary" />
        </div>
        <h1>Mini Delivery Router</h1>
        <p>Acesse sua conta para gerenciar rotas</p>
      </div>

      <form @submit.prevent="handleLogin" class="login-form">
        <div v-if="error" class="error-badge mb-4">{{ error }}</div>
        
        <div class="form-group">
          <label>Email</label>
          <div class="input-icon">
            <Mail :size="20" />
            <input v-model="email" type="email" required placeholder="seu@email.com" />
          </div>
        </div>

        <div class="form-group">
          <label>Senha</label>
          <div class="input-icon">
            <Lock :size="20" />
            <input v-model="password" type="password" required placeholder="••••••••" />
          </div>
        </div>

        <button type="submit" class="btn btn-primary w-full" :disabled="loading">
          <Loader2 v-if="loading" class="animate-spin" :size="20" />
          <LogIn v-else :size="20" />
          {{ loading ? 'Entrando...' : 'Entrar' }}
        </button>
      </form>
      
      <div class="login-footer">
        <p>Login de teste: admin@trackland.com / password123</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: radial-gradient(circle at top right, rgba(99, 102, 241, 0.15), transparent),
              radial-gradient(circle at bottom left, rgba(236, 72, 153, 0.1), transparent);
}

.login-card {
  width: 100%;
  max-width: 400px;
  padding: 2.5rem;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 24px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(10px);
}

.login-header {
  text-align: center;
  margin-bottom: 2.5rem;
}

.logo {
  width: 80px;
  height: 80px;
  background: rgba(99, 102, 241, 0.1);
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 1.5rem;
}

.login-header h1 {
  font-size: 1.5rem;
  font-weight: 800;
  margin-bottom: 0.5rem;
  background: linear-gradient(to right, #fff, #94a3b8);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.login-header p {
  color: var(--text-muted);
  font-size: 0.875rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  font-size: 0.875rem;
  font-weight: 500;
  margin-bottom: 0.5rem;
  color: var(--text-muted);
}

.input-icon {
  position: relative;
}

.input-icon svg {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--text-muted);
}

.input-icon input {
  width: 100%;
  padding: 0.75rem 0.75rem 0.75rem 42px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--border);
  border-radius: 12px;
  color: white;
  transition: all 0.2s;
}

.input-icon input:focus {
  outline: none;
  border-color: var(--primary);
  background: rgba(255, 255, 255, 0.08);
}

.error-badge {
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.2);
  color: #f87171;
  padding: 0.75rem;
  border-radius: 12px;
  font-size: 0.875rem;
  text-align: center;
}

.login-footer {
  margin-top: 2rem;
  text-align: center;
  font-size: 0.75rem;
  color: var(--text-muted);
}

.animate-spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
</style>
