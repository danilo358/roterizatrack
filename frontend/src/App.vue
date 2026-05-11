<script setup lang="ts">
import { useRoute, useRouter } from 'vue-router';
import { Map, Plus, Truck, MapPin, BarChart3, LogOut } from 'lucide-vue-next';
import { computed } from 'vue';

const router = useRouter();
const route = useRoute();

const isLoginPage = computed(() => route.name === 'login');

const handleLogout = () => {
  localStorage.removeItem('user');
  router.push('/login');
};
</script>

<template>
  <div class="app-layout">
    <nav class="sidebar" v-if="!isLoginPage">
      <div class="logo">
        <img src="/favicon.png" alt="RoterizaTrack" class="logo-img" />
        <span>RoterizaTrack</span>
      </div>
      
      <div class="nav-links">
        <router-link to="/" class="nav-link" active-class="active">
          <Map :size="20" /> Roteirização
        </router-link>

        <router-link to="/relatorios" class="nav-link" active-class="active">
          <BarChart3 :size="20" /> Relatórios
        </router-link>
        
        <div class="nav-section">Cadastros</div>
        
        <router-link to="/enderecos/novo" class="nav-link" active-class="active">
          <Plus :size="20" /> Novo Endereço
        </router-link>
        
        <router-link to="/veiculos/novo" class="nav-link" active-class="active">
          <Plus :size="20" /> Novo Veículo
        </router-link>
      </div>

      <div class="mt-auto px-4">
        <button class="logout-btn" @click="handleLogout">
          <LogOut :size="16" />
          <span>Sair do Sistema</span>
        </button>
      </div>
    </nav>

    <main class="content" :class="{ 'no-sidebar': isLoginPage }">
      <router-view />
    </main>
  </div>
</template>

<style>
:root {
  --sidebar-width: 260px;
}

.app-layout {
  display: flex;
  min-height: 100vh;
}

.sidebar {
  width: var(--sidebar-width);
  background: var(--surface);
  border-right: 1px solid var(--border);
  padding: 2rem 1rem;
  display: flex;
  flex-direction: column;
  position: fixed;
  height: 100vh;
}

.logo {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 1.25rem;
  font-weight: 800;
  margin-bottom: 3rem;
  padding: 0 1rem;
}

.logo-img {
  width: 32px;
  height: 32px;
  object-fit: contain;
}

.nav-links {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.nav-link {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  border-radius: var(--radius);
  color: var(--text-muted);
  text-decoration: none;
  font-weight: 600;
  transition: all 0.2s;
}

.nav-link:hover {
  background: rgba(255, 255, 255, 0.05);
  color: var(--text);
}

.nav-link.active {
  background: var(--primary);
  color: white;
}

.nav-section {
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  color: var(--text-muted);
  margin: 1.5rem 0 0.5rem 1rem;
  letter-spacing: 0.05em;
}

.content {
  flex: 1;
  margin-left: var(--sidebar-width);
  padding: 2rem;
  background: var(--bg);
}

.content.no-sidebar {
  margin-left: 0;
}

.logout-btn {
  width: 100%;
  padding: 0.6rem 1rem;
  background: rgba(239, 68, 68, 0.08);
  border: 1px solid rgba(239, 68, 68, 0.2);
  border-radius: 12px;
  color: #f87171;
  font-weight: 600;
  font-size: 0.85rem;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
}

.logout-btn:hover {
  background: rgba(239, 68, 68, 0.15);
  transform: translateY(-1px);
}

/* Global transitions */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
