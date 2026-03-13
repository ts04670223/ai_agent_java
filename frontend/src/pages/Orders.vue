<template>
  <v-container class="py-6">
    <h1 class="text-h4 font-weight-bold mb-6">我的訂單</h1>

    <div v-if="loading" class="d-flex justify-center py-12">
      <v-progress-circular indeterminate color="primary" size="48" />
    </div>

    <div v-else-if="orders.length === 0" class="text-center py-12">
      <v-icon size="80" color="grey">mdi-shopping</v-icon>
      <p class="text-h6 mt-4 text-medium-emphasis">目前還沒有訂單</p>
      <v-btn color="primary" class="mt-4" to="/shop">去購物</v-btn>
    </div>

    <v-row v-else>
      <v-col v-for="order in orders" :key="order.id" cols="12" md="6">
        <v-card class="mb-4" @click="loadOrderDetail(order.id)" style="cursor: pointer">
          <v-card-title class="d-flex align-center justify-space-between">
            <span class="text-body-1">訂單 #{{ order.orderNumber || order.id }}</span>
            <v-chip :color="getStatusColor(order.status)" size="small">
              {{ getStatusText(order.status) }}
            </v-chip>
          </v-card-title>
          <v-card-text>
            <v-row dense>
              <v-col cols="12">
                <v-icon size="small" class="mr-1">mdi-calendar</v-icon>
                {{ formatDate(order.createdAt) }}
              </v-col>
              <v-col cols="12" v-if="order.shippingAddress">
                <v-icon size="small" class="mr-1">mdi-map-marker</v-icon>
                {{ order.shippingAddress }}
              </v-col>
              <v-col cols="12" v-if="order.phone">
                <v-icon size="small" class="mr-1">mdi-phone</v-icon>
                {{ order.phone }}
              </v-col>
              <v-col cols="12">
                <v-icon size="small" class="mr-1">mdi-credit-card</v-icon>
                總計: <strong class="text-primary">${{ parseFloat(order.total || 0).toFixed(0) }}</strong>
              </v-col>
            </v-row>
          </v-card-text>
          <v-card-actions>
            <v-btn variant="text" color="primary" size="small">查看詳情</v-btn>
          </v-card-actions>
        </v-card>
      </v-col>
    </v-row>

    <!-- 訂單詳情 Dialog -->
    <v-dialog v-model="isDialogOpen" max-width="600">
      <v-card v-if="selectedOrder">
        <v-card-title class="d-flex align-center justify-space-between">
          訂單詳情 #{{ selectedOrder.orderNumber || selectedOrder.id }}
          <v-chip :color="getStatusColor(selectedOrder.status)" size="small">
            {{ getStatusText(selectedOrder.status) }}
          </v-chip>
        </v-card-title>
        <v-card-text>
          <v-row dense class="mb-3">
            <v-col cols="12">
              <v-icon size="small" class="mr-1">mdi-calendar</v-icon>
              下單時間: {{ formatDate(selectedOrder.createdAt) }}
            </v-col>
            <v-col cols="12" v-if="selectedOrder.shippingAddress">
              <v-icon size="small" class="mr-1">mdi-map-marker</v-icon>
              收貨地址: {{ selectedOrder.shippingAddress }}
            </v-col>
            <v-col cols="12" v-if="selectedOrder.phone">
              <v-icon size="small" class="mr-1">mdi-phone</v-icon>
              聯絡電話: {{ selectedOrder.phone }}
            </v-col>
          </v-row>

          <v-divider class="mb-3" />
          <p class="text-subtitle-2 mb-2">訂購商品</p>
          <v-list density="compact">
            <v-list-item
              v-for="item in (selectedOrder.items || selectedOrder.orderItems || [])"
              :key="item.id"
              :title="`${item.productName || item.product?.name || '商品'} x${item.quantity}`"
              :subtitle="`$${parseFloat(item.price || 0).toFixed(0)}`"
            />
          </v-list>
          <v-divider class="mt-2 mb-3" />
          <div class="d-flex justify-space-between text-body-1 font-weight-bold">
            <span>訂單總計</span>
            <span class="text-primary">${{ parseFloat(selectedOrder.total || 0).toFixed(0) }}</span>
          </div>

          <div v-if="selectedOrder.note" class="mt-3">
            <v-icon size="small" class="mr-1">mdi-information</v-icon>
            備註: {{ selectedOrder.note }}
          </div>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn @click="isDialogOpen = false">關閉</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'
import { orderAPI } from '../services/api.js'
import { useAuthStore } from '../stores/authStore.js'

const router = useRouter()
const toast = useToast()
const authStore = useAuthStore()
const user = computed(() => authStore.user)

const orders = ref([])
const loading = ref(true)
const selectedOrder = ref(null)
const isDialogOpen = ref(false)

function getStatusText(status) {
  const map = {
    PENDING: '待處理',
    PROCESSING: '處理中',
    SHIPPED: '已發貨',
    DELIVERED: '已送達',
    CANCELLED: '已取消',
  }
  return map[status] || status
}

function getStatusColor(status) {
  const map = {
    PENDING: 'warning',
    PROCESSING: 'info',
    SHIPPED: 'primary',
    DELIVERED: 'success',
    CANCELLED: 'error',
  }
  return map[status] || 'grey'
}

function formatDate(dateStr) {
  if (!dateStr) return ''
  return new Date(dateStr).toLocaleString('zh-TW')
}

async function loadOrders() {
  try {
    const response = await orderAPI.getUserOrders(user.value.id)
    const data = response.data?.data || response.data || []
    orders.value = Array.isArray(data) ? data : []
    loading.value = false
  } catch {
    toast.error('載入訂單失敗')
    orders.value = []
    loading.value = false
  }
}

async function loadOrderDetail(orderId) {
  try {
    const response = await orderAPI.getOrder(orderId)
    selectedOrder.value = response.data?.data || response.data
    isDialogOpen.value = true
  } catch {
    toast.error('載入訂單詳情失敗')
  }
}

onMounted(() => {
  if (!user.value?.id) {
    toast.error('請先登入')
    router.push('/login')
    return
  }
  loadOrders()
})
</script>
