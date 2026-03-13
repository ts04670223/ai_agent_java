<template>
  <v-app>
    <!-- 頂部導航列 -->
    <v-app-bar color="primary" elevation="2">
      <v-app-bar-nav-icon @click="drawer = !drawer" />
      <v-app-bar-title>
        <RouterLink to="/shop" class="text-white text-decoration-none">
          🛍️ 購物系統
        </RouterLink>
      </v-app-bar-title>

      <template v-slot:append>
        <!-- 聊天圖示 -->
        <v-btn icon @click="$router.push('/chat')">
          <v-badge :content="unreadCount > 0 ? unreadCount : ''" :model-value="unreadCount > 0" color="error">
            <v-icon>mdi-message</v-icon>
          </v-badge>
        </v-btn>

        <!-- 購物車圖示 -->
        <v-btn icon @click="$router.push('/cart')">
          <v-badge :content="cartCount > 0 ? cartCount : ''" :model-value="cartCount > 0" color="error">
            <v-icon>mdi-cart</v-icon>
          </v-badge>
        </v-btn>

        <!-- 使用者選單 -->
        <v-menu>
          <template v-slot:activator="{ props }">
            <v-btn icon v-bind="props">
              <v-avatar color="secondary" size="36">
                <span class="text-white text-body-2">{{ userInitial }}</span>
              </v-avatar>
            </v-btn>
          </template>
          <v-list>
            <v-list-item prepend-icon="mdi-account" title="個人資料" @click="$router.push('/profile')" />
            <v-list-item prepend-icon="mdi-heart" title="願望清單" @click="$router.push('/wishlist')" />
            <v-list-item prepend-icon="mdi-receipt" title="我的訂單" @click="$router.push('/orders')" />
            <v-list-item prepend-icon="mdi-key" title="Passkeys" @click="$router.push('/passkeys')" />
            <v-divider />
            <v-list-item
              v-if="user?.role === 'ADMIN'"
              prepend-icon="mdi-shield-account"
              title="管理後台"
              @click="$router.push('/admin')"
            />
            <v-divider v-if="user?.role === 'ADMIN'" />
            <v-list-item prepend-icon="mdi-logout" title="登出" @click="handleLogout" />
          </v-list>
        </v-menu>
      </template>
    </v-app-bar>

    <!-- 側邊導航抽屜 -->
    <v-navigation-drawer v-model="drawer" temporary>
      <v-list-item
        :title="user?.name || user?.username || '用戶'"
        :subtitle="user?.email"
        nav
      >
        <template v-slot:prepend>
          <v-avatar color="primary">
            <span class="text-white">{{ userInitial }}</span>
          </v-avatar>
        </template>
      </v-list-item>
      <v-divider />
      <v-list density="compact" nav>
        <v-list-item prepend-icon="mdi-store" title="商城" to="/shop" />
        <v-list-item prepend-icon="mdi-message" title="聊天" to="/chat">
          <template v-slot:append>
            <v-badge v-if="unreadCount > 0" :content="unreadCount" color="error" inline />
          </template>
        </v-list-item>
        <v-list-item prepend-icon="mdi-cart" title="購物車" to="/cart">
          <template v-slot:append>
            <v-badge v-if="cartCount > 0" :content="cartCount" color="error" inline />
          </template>
        </v-list-item>
        <v-list-item prepend-icon="mdi-receipt" title="我的訂單" to="/orders" />
        <v-list-item prepend-icon="mdi-heart" title="願望清單" to="/wishlist" />
        <v-list-item prepend-icon="mdi-account" title="個人資料" to="/profile" />
        <v-list-item prepend-icon="mdi-key" title="Passkeys" to="/passkeys" />
        <v-divider class="my-2" />
        <v-list-item
          v-if="user?.role === 'ADMIN'"
          prepend-icon="mdi-shield-account"
          title="管理後台"
          to="/admin"
        />
        <v-list-item prepend-icon="mdi-logout" title="登出" @click="handleLogout" />
      </v-list>
    </v-navigation-drawer>

    <!-- 主要內容 -->
    <v-main>
      <RouterView />
    </v-main>
  </v-app>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { RouterView, RouterLink, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/authStore.js'
import { cartAPI, chatAPI } from '../services/api.js'
import { cartEvents as cartEventsUtil } from '../utils/cartEvents.js'

const router = useRouter()
const authStore = useAuthStore()
const user = computed(() => authStore.user)
const userInitial = computed(() => {
  const name = user.value?.name || user.value?.username || '?'
  return name.charAt(0).toUpperCase()
})

const drawer = ref(false)
const cartCount = ref(0)
const unreadCount = ref(0)

async function loadCartCount() {
  if (!user.value?.id) return
  try {
    const response = await cartAPI.getCart(user.value.id)
    const cartData = response.data?.data || response.data
    cartCount.value = cartData?.items?.reduce((sum, item) => sum + (item.quantity || 0), 0) || 0
  } catch {}
}

async function loadUnreadCount() {
  if (!user.value?.id) return
  try {
    const response = await chatAPI.getUnreadCount(user.value.id)
    unreadCount.value = response.data?.unreadCount || response.data?.data?.unreadCount || 0
  } catch {}
}

function handleLogout() {
  authStore.logout()
  router.push('/login')
}

let interval = null

onMounted(() => {
  loadCartCount()
  loadUnreadCount()
  interval = setInterval(() => {
    loadCartCount()
    loadUnreadCount()
  }, 10000)

  cartEventsUtil.subscribe(() => loadCartCount())
})

onUnmounted(() => {
  if (interval) clearInterval(interval)
})
</script>
