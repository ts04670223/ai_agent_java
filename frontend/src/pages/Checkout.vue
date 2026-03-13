<template>
  <v-container class="py-6" style="max-width: 900px">
    <v-btn variant="text" prepend-icon="mdi-arrow-left" to="/shop" class="mb-6">返回商城</v-btn>

    <!-- 載入中 -->
    <div v-if="loading" class="d-flex justify-center py-12">
      <v-progress-circular indeterminate color="primary" size="48" />
    </div>

    <v-row v-else>
      <!-- 收貨資訊表單 -->
      <v-col cols="12" md="6">
        <h1 class="text-h4 font-weight-bold mb-6">結帳</h1>
        <v-card>
          <v-card-title>收貨信息</v-card-title>
          <v-card-text>
            <v-form @submit.prevent="handleSubmit">
              <v-textarea
                v-model="formData.shippingAddress"
                label="收貨地址 *"
                variant="outlined"
                rows="3"
                required
                placeholder="請輸入詳細地址"
                class="mb-3"
              />
              <v-text-field
                v-model="formData.phone"
                label="聯絡電話 *"
                type="tel"
                variant="outlined"
                required
                placeholder="請輸入手機號碼 (09xxxxxxxx)"
                class="mb-3"
              />
              <v-textarea
                v-model="formData.note"
                label="訂單備註"
                variant="outlined"
                rows="2"
                placeholder="有什麼需要告訴我們的嗎？"
                class="mb-4"
              />
              <div class="d-flex gap-3">
                <v-btn variant="outlined" to="/shop" class="flex-grow-1">取消</v-btn>
                <v-btn
                  type="submit"
                  color="primary"
                  class="flex-grow-1"
                  :loading="submitting"
                  prepend-icon="mdi-credit-card"
                >
                  確認訂單
                </v-btn>
              </div>
            </v-form>
          </v-card-text>
        </v-card>
      </v-col>

      <!-- 訂單摘要 -->
      <v-col cols="12" md="6">
        <h2 class="text-h5 mb-4">訂單摘要</h2>
        <v-card>
          <v-list density="compact">
            <v-list-item
              v-for="item in cartItems"
              :key="item.id"
              :title="`${item.productName || item.product?.name} x${item.quantity}`"
              :subtitle="`$${parseFloat(item.subtotal || (item.price * item.quantity) || 0).toFixed(0)}`"
            />
          </v-list>
          <v-divider />
          <v-card-text>
            <div class="d-flex justify-space-between mb-1">
              <span>商品小計</span>
              <span>${{ parseFloat(total).toFixed(0) }}</span>
            </div>
            <div class="d-flex justify-space-between mb-1">
              <span>運費</span>
              <span>$60</span>
            </div>
            <v-divider class="my-2" />
            <div class="d-flex justify-space-between text-body-1 font-weight-bold">
              <span>總計</span>
              <span class="text-primary">${{ (parseFloat(total) + 60).toFixed(0) }}</span>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'
import { orderAPI, cartAPI } from '../services/api.js'
import { useAuthStore } from '../stores/authStore.js'
import { cartEvents } from '../utils/cartEvents.js'

const router = useRouter()
const toast = useToast()
const authStore = useAuthStore()
const user = computed(() => authStore.user)

const cart = ref(null)
const cartItems = ref([])
const loading = ref(true)
const submitting = ref(false)
const formData = ref({
  shippingAddress: '',
  phone: '',
  note: '',
})

const total = computed(() =>
  cart.value?.total ||
  cartItems.value.reduce((sum, item) => sum + parseFloat(item.subtotal || item.price * item.quantity || 0), 0)
)

async function loadCart() {
  if (!user.value?.id) return
  try {
    const response = await cartAPI.getCart(user.value.id)
    const cartData = response.data?.data || response.data
    cart.value = cartData
    cartItems.value = cartData?.items || []
    if (!cartData?.items || cartData.items.length === 0) {
      toast.error('購物車是空的！')
      router.push('/shop')
    }
    loading.value = false
  } catch {
    toast.error('載入購物車失敗')
    loading.value = false
  }
}

async function handleSubmit() {
  if (!formData.value.shippingAddress.trim()) {
    toast.error('請填寫收貨地址！')
    return
  }
  if (!formData.value.phone.trim()) {
    toast.error('請填寫聯絡電話！')
    return
  }
  const phoneRegex = /^09\d{8}$/
  if (!phoneRegex.test(formData.value.phone)) {
    toast.error('請輸入正確的台灣手機號碼格式 (例如: 0912345678)')
    return
  }

  submitting.value = true
  try {
    const params = new URLSearchParams({
      userId: user.value.id.toString(),
      shippingAddress: formData.value.shippingAddress,
      phone: formData.value.phone,
    })
    if (formData.value.note) params.append('note', formData.value.note)

    const response = await orderAPI.createOrder(`?${params.toString()}`)
    const orderData = response.data?.data || response.data

    try {
      await cartAPI.clearCart(user.value.id)
      cartEvents.notify()
    } catch {}

    toast.success('訂單建立成功！訂單編號: ' + (orderData.orderNumber || orderData.id))
    router.push('/orders')
  } catch (err) {
    toast.error(err.response?.data?.error || '建立訂單失敗')
    submitting.value = false
  }
}

onMounted(() => {
  if (!user.value?.id) {
    toast.error('請先登入')
    router.push('/login')
    return
  }
  formData.value.phone = user.value.phone || ''
  loadCart()
})
</script>
