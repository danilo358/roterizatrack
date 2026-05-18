<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import axios from 'axios';
import { LogIn, Lock, Mail, Loader2, User } from 'lucide-vue-next';

const router = useRouter();
const name = ref('');
const email = ref('');
const password = ref('');
const passwordConfirmation = ref('');
const loading = ref(false);
const error = ref('');

const handleRegister = async () => {
  if (password.value !== passwordConfirmation.value) {
    error.value = 'As senhas não coincidem';
    return;
  }
  
  loading.value = true;
  error.value = '';
  try {
    const res = await axios.post('http://localhost:3000/auth/register', {
      name: name.value,
      email: email.value,
      password: password.value,
      password_confirmation: passwordConfirmation.value
    });
    
    localStorage.setItem('user', JSON.stringify(res.data));
    router.push('/');
  } catch (err: any) {
    error.value = err.response?.data?.error?.join(', ') || 'Erro ao fazer cadastro';
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
          <img src="/favicon.png" alt="Logo" class="logo-img" />
        </div>
        <h1>Criar Conta</h1>
        <p>Junte-se à logística inteligente</p>
      </div>

      <form @submit.prevent="handleRegister" class="login-form">
        <div v-if="error" class="error-badge mb-4">{{ error }}</div>
        
        <div class="form-group">
          <label>Nome</label>
          <div class="input-icon">
            <User :size="20" />
            <input v-model="name" type="text" required placeholder="Seu Nome" />
          </div>
        </div>

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

        <div class="form-group">
          <label>Confirmar Senha</label>
          <div class="input-icon">
            <Lock :size="20" />
            <input v-model="passwordConfirmation" type="password" required placeholder="••••••••" />
          </div>
        </div>

        <button type="submit" class="btn btn-primary w-full" :disabled="loading">
          <Loader2 v-if="loading" class="animate-spin" :size="20" />
          <LogIn v-else :size="20" />
          {{ loading ? 'Cadastrando...' : 'Cadastrar' }}
        </button>
      </form>
      
      <div class="login-footer">
        <p>Já tem uma conta? <router-link to="/login" class="link">Faça login</router-link></p>
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
  background: var(--bg);
}

.login-card {
  width: 100%;
  max-width: 400px;
  padding: 3rem 2.5rem;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 28px;
  box-shadow: var(--shadow);
}

.login-header {
  text-align: center;
  margin-bottom: 2.5rem;
}

.logo {
  width: 72px;
  height: 72px;
  background: var(--surface-light);
  border: 1px solid var(--border);
  border-radius: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 1.5rem;
}

.logo-img {
  width: 48px;
  height: 48px;
  object-fit: contain;
}

.login-header h1 {
  font-size: 1.75rem;
  font-weight: 900;
  margin-bottom: 0.5rem;
  color: var(--text);
  letter-spacing: -0.03em;
}

.login-header p {
  color: var(--text-muted);
  font-size: 0.9rem;
  font-weight: 500;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  font-size: 0.8rem;
  font-weight: 700;
  margin-bottom: 0.6rem;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.input-icon {
  position: relative;
}

.input-icon svg {
  position: absolute;
  left: 16px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--text-muted);
}

.input-icon input {
  width: 100%;
  padding: 0.9rem 1rem 0.9rem 48px;
  background: var(--surface-light);
  border: 1px solid var(--border);
  border-radius: 12px;
  color: var(--text);
  font-size: 1rem;
  transition: all var(--transition);
}

.input-icon input:focus {
  outline: none;
  border-color: var(--primary);
  background: var(--surface);
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.1);
}

.error-badge {
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.2);
  color: var(--error);
  padding: 0.85rem;
  border-radius: 12px;
  font-size: 0.85rem;
  font-weight: 600;
  text-align: center;
  margin-bottom: 1.5rem;
}

.login-footer {
  margin-top: 2.5rem;
  text-align: center;
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--text-muted);
}

.link {
  color: var(--primary);
  text-decoration: none;
  font-weight: 700;
}

.link:hover {
  text-decoration: underline;
}

.animate-spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.w-full { width: 100%; }
.mb-4 { margin-bottom: 1rem; }
</style>
