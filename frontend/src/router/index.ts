import { createRouter, createWebHistory } from 'vue-router';
import RoutingView from '../views/RoutingView.vue';
import AddressFormView from '../views/AddressFormView.vue';
import VehicleFormView from '../views/VehicleFormView.vue';
import LoginView from '../views/LoginView.vue';
import ReportsView from '../views/ReportsView.vue';

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: LoginView
    },
    {
      path: '/',
      name: 'routing',
      component: RoutingView,
      meta: { requiresAuth: true }
    },
    {
      path: '/relatorios',
      name: 'reports',
      component: ReportsView,
      meta: { requiresAuth: true }
    },
    {
      path: '/enderecos/novo',
      name: 'new-address',
      component: AddressFormView,
      meta: { requiresAuth: true }
    },
    {
      path: '/veiculos/novo',
      name: 'new-vehicle',
      component: VehicleFormView,
      meta: { requiresAuth: true }
    }
  ]
});

router.beforeEach((to, from, next) => {
  const loggedIn = localStorage.getItem('user');

  if (to.matched.some(record => record.meta.requiresAuth) && !loggedIn) {
    next('/login');
  } else if (to.name === 'login' && loggedIn) {
    next('/');
  } else {
    next();
  }
});

export default router;
