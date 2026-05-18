import { createRouter, createWebHistory } from 'vue-router';
import RoutingView from '../views/RoutingView.vue';
import AddressFormView from '../views/AddressFormView.vue';
import VehicleFormView from '../views/VehicleFormView.vue';
import ReportsView from '../views/ReportsView.vue';

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue')
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('../views/RegisterView.vue')
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
