import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/authStore.js'

const routes = [
  {
    path: '/login',
    component: () => import('../pages/Login.vue'),
    meta: { public: true },
  },
  {
    path: '/register',
    component: () => import('../pages/Register.vue'),
    meta: { public: true },
  },
  {
    path: '/',
    component: () => import('../layouts/Layout.vue'),
    children: [
      { path: '', redirect: '/shop' },
      { path: 'shop', component: () => import('../pages/Shop.vue') },
      { path: 'product/:id', component: () => import('../pages/ProductDetail.vue') },
      { path: 'cart', component: () => import('../pages/Cart.vue') },
      { path: 'checkout', component: () => import('../pages/Checkout.vue') },
      { path: 'orders', component: () => import('../pages/Orders.vue') },
      { path: 'profile', component: () => import('../pages/Profile.vue') },
      { path: 'wishlist', component: () => import('../pages/Wishlist.vue') },
      { path: 'passkeys', component: () => import('../pages/PasskeyManager.vue') },
      { path: 'chat', component: () => import('../pages/Chat.vue') },
      {
        path: 'admin',
        component: () => import('../pages/admin/Dashboard.vue'),
        meta: { adminOnly: true },
      },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  if (!to.meta.public && !authStore.isAuthenticated) {
    next('/login')
  } else if (to.meta.adminOnly && authStore.user?.role !== 'ADMIN') {
    next('/shop')
  } else if (to.meta.public && authStore.isAuthenticated) {
    next('/shop')
  } else {
    next()
  }
})

export default router
