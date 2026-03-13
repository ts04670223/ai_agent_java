<template>
  <v-container class="py-6">
    <!-- 載入中 -->
    <div v-if="loading" class="d-flex justify-center py-12">
      <v-progress-circular indeterminate color="primary" size="48" />
    </div>

    <!-- 購物車空時 -->
    <div v-else-if="cartItems.length === 0" class="text-center py-12">
      <v-icon size="80" color="grey">mdi-cart-remove</v-icon>
      <h2 class="text-h5 mt-4 mb-2">購物車是空的</h2>
      <p class="text-medium-emphasis mb-6">快去挑選您喜歡的商品吧！</p>
      <v-btn color="primary" size="large" to="/shop" prepend-icon="mdi-store">繼續購物</v-btn>
    </div>

    <!-- 購物車內容 -->
    <template v-else>
      <h1 class="text-h4 font-weight-bold mb-6">購物車</h1>

      <v-row>
        <!-- 商品列表 -->
        <v-col cols="12" md="8">
          <v-card v-for="item in cartItems" :key="item.id" class="mb-4">
            <v-card-text>
              <v-row align="center">
                <!-- 商品圖片 -->
                <v-col cols="3" sm="2">
                  <v-img
                    v-if="item.product?.imageUrl"
                    :src="item.product.imageUrl"
                    :alt="item.productName || item.product?.name"
                    width="100"
                    height="100"
                    cover
                    rounded
                  />
                  <v-sheet
                    v-else
                    color="primary"
                    rounded
                    width="100"
                    height="100"
                    class="d-flex align-center justify-center"
                  >
                    <span class="text-white text-h6">
                      {{ (item.productName || item.product?.name || 'NA').substring(0, 2).toUpperCase() }}
                    </span>
                  </v-sheet>
                </v-col>

                <!-- 商品資訊 -->
                <v-col cols="9" sm="5">
                  <div class="text-body-1 font-weight-medium">
                    {{ item.productName || item.product?.name }}
                  </div>
                  <div v-if="item.product?.category" class="text-caption text-medium-emphasis">
                    分類: {{ item.product.category }}
                  </div>
                  <div class="text-body-1 font-weight-bold text-primary mt-1">
                    ${{ parseFloat(item.price || 0).toFixed(0) }}
                  </div>
                </v-col>

                <!-- 數量控制 -->
                <v-col cols="6" sm="3">
                  <div class="d-flex align-center justify-center ga-2">
                    <v-btn icon size="small" variant="outlined"
                      @click="handleQuantityChange(item.id, item.quantity - 1)"
                      :disabled="item.quantity <= 1">
                      <v-icon>mdi-minus</v-icon>
                    </v-btn>
                    <span class="text-body-1 font-weight-bold" style="min-width: 24px; text-align: center">
                      {{ item.quantity }}
                    </span>
                    <v-btn icon size="small" variant="outlined"
                      @click="handleQuantityChange(item.id, item.quantity + 1)">
                      <v-icon>mdi-plus</v-icon>
                    </v-btn>
                  </div>
                </v-col>

                <!-- 小計與刪除 -->
                <v-col cols="6" sm="2" class="text-center">
                  <div class="text-body-1 font-weight-semibold mb-2">
                    ${{ parseFloat(item.subtotal || (item.price * item.quantity) || 0).toFixed(0) }}
                  </div>
                  <v-btn icon size="small" color="error" variant="outlined"
                    @click="handleRemoveItem(item.id)">
                    <v-icon>mdi-delete</v-icon>
                  </v-btn>
                </v-col>
              </v-row>
            </v-card-text>
          </v-card>
        </v-col>

        <!-- 訂單摘要 -->
        <v-col cols="12" md="4">
          <v-card class="sticky-top" style="top: 80px">
            <v-card-title>訂單摘要</v-card-title>
            <v-card-text>
              <div v-for="item in cartItems" :key="item.id" class="d-flex justify-space-between mb-1 text-body-2">
                <span>{{ item.productName || item.product?.name }} x {{ item.quantity }}</span>
                <span>${{ parseFloat(item.subtotal || (item.price * item.quantity) || 0).toFixed(0) }}</span>
              </div>
              <v-divider class="my-3" />
              <div class="d-flex justify-space-between mb-1">
                <span>小計</span>
                <span>${{ parseFloat(cart?.total || 0).toFixed(0) }}</span>
              </div>
              <div class="d-flex justify-space-between mb-1">
                <span>運費</span>
                <span>$60</span>
              </div>
              <v-divider class="my-3" />
              <div class="d-flex justify-space-between text-body-1 font-weight-bold">
                <span>總計</span>
                <span class="text-primary">${{ (parseFloat(cart?.total || 0) + 60).toFixed(0) }}</span>
              </div>
            </v-card-text>
            <v-card-actions class="flex-column pa-4 ga-2">
              <v-btn color="primary" block size="large" prepend-icon="mdi-cart" @click="handleCheckout">
                結帳
              </v-btn>
              <v-btn color="error" variant="outlined" block @click="clearCartDialog = true">
                清空購物車
              </v-btn>
              <v-btn variant="text" block to="/shop">繼續購物</v-btn>
            </v-card-actions>
          </v-card>
        </v-col>
      </v-row>
    </template>

    <!-- 清空確認 Dialog -->
    <v-dialog v-model="clearCartDialog" max-width="360">
      <v-card>
        <v-card-title>清空購物車</v-card-title>
        <v-card-text>確定要清空購物車內的所有商品嗎？此操作無法復原。</v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn @click="clearCartDialog = false">取消</v-btn>
          <v-btn color="error" @click="handleClearCart">清空</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'
import { cartAPI } from '../services/api.js'
import { useAuthStore } from '../stores/authStore.js'
import { cartEvents } from '../utils/cartEvents.js'

const router = useRouter()
const toast = useToast()
const authStore = useAuthStore()
const user = computed(() => authStore.user)

const cart = ref(null)
const cartItems = ref([])
const loading = ref(true)
const clearCartDialog = ref(false)

async function loadCart() {
  if (!user.value?.id) return
  try {
    const response = await cartAPI.getCart(user.value.id)
    const cartData = response.data?.data || response.data
    cart.value = cartData
    cartItems.value = cartData?.items || []
    loading.value = false
  } catch {
    toast.error('載入購物車失敗')
    loading.value = false
  }
}

async function handleQuantityChange(itemId, newQuantity) {
  if (newQuantity < 1) { await handleRemoveItem(itemId); return }
  try {
    await cartAPI.updateCartItem(user.value.id, itemId, newQuantity)
    await loadCart()
    cartEvents.notify()
    toast.success('數量已更新')
  } catch (err) {
    toast.error(err.response?.data?.error || '更新失敗')
  }
}

async function handleRemoveItem(itemId) {
  try {
    await cartAPI.removeFromCart(user.value.id, itemId)
    await loadCart()
    cartEvents.notify()
    toast.success('已從購物車移除')
  } catch {
    toast.error('移除失敗')
  }
}

async function handleClearCart() {
  clearCartDialog.value = false
  try {
    await cartAPI.clearCart(user.value.id)
    await loadCart()
    cartEvents.notify()
    toast.success('購物車已清空')
  } catch {
    toast.error('清空購物車失敗')
  }
}

function handleCheckout() {
  if (cartItems.value.length === 0) { toast.error('購物車是空的！'); return }
  router.push('/checkout')
}

onMounted(() => {
  if (!user.value?.id) { router.push('/login'); return }
  loadCart()
})
</script>
