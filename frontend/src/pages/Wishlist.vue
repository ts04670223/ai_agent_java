<template>
  <v-container class="py-6">
    <h1 class="text-h4 font-weight-bold mb-6">願望清單</h1>

    <div v-if="loading" class="d-flex justify-center py-12">
      <v-progress-circular indeterminate color="primary" />
    </div>

    <div v-else-if="wishlistItems.length === 0" class="text-center py-12">
      <v-icon size="80" color="grey">mdi-heart-off</v-icon>
      <p class="text-h6 mt-4 text-medium-emphasis">願望清單是空的</p>
      <v-btn color="primary" class="mt-4" to="/shop">去購物</v-btn>
    </div>

    <v-row v-else>
      <v-col
        v-for="item in wishlistItems"
        :key="item.id"
        cols="12" sm="6" md="4" lg="3"
      >
        <v-card height="100%" class="d-flex flex-column">
          <!-- 商品圖片 -->
          <v-img
            v-if="item.product?.images?.[0]?.url"
            :src="item.product.images[0].url"
            :alt="item.product.name"
            height="200"
            cover
          />
          <v-sheet v-else height="200" color="grey-lighten-3" class="d-flex align-center justify-center">
            <v-icon size="64" color="grey">mdi-image-off</v-icon>
          </v-sheet>

          <v-card-title class="text-body-1 pb-1">
            <span class="text-truncate d-block">{{ item.product?.name }}</span>
          </v-card-title>
          <v-card-text class="flex-grow-1 py-1">
            <span class="text-body-1 font-weight-bold text-primary">
              ${{ parseFloat(item.product?.price || 0).toFixed(0) }}
            </span>
          </v-card-text>

          <v-card-actions class="pa-3 pt-0 d-flex gap-2">
            <v-btn
              color="primary"
              variant="flat"
              class="flex-grow-1"
              prepend-icon="mdi-cart-plus"
              @click="addToCart(item.product?.id)"
            >
              加入購物車
            </v-btn>
            <v-btn
              icon
              variant="outlined"
              size="small"
              color="error"
              @click="removeFromWishlist(item.product?.id)"
            >
              <v-icon>mdi-delete</v-icon>
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'
import api, { cartAPI, wishlistAPI } from '../services/api.js'
import { useAuthStore } from '../stores/authStore.js'

const router = useRouter()
const toast = useToast()
const authStore = useAuthStore()
const user = computed(() => authStore.user)

const wishlistItems = ref([])
const loading = ref(true)

async function loadWishlist() {
  try {
    const response = await api.get('/wishlist')
    const items = response.data?.items ?? response.data ?? []
    wishlistItems.value = items.map(item => ({
      id: item.id,
      createdAt: item.createdAt,
      product: {
        id: item.productId,
        name: item.productName,
        price: item.productPrice,
        images: (item.productImages || []).map(url => ({ url })),
      },
    }))
    loading.value = false
  } catch (err) {
    if (err.response?.status === 401) router.push('/login')
    loading.value = false
  }
}

async function removeFromWishlist(productId) {
  try {
    await api.delete(`/wishlist/items/${productId}`)
    toast.success('已從願望清單移除')
    await loadWishlist()
  } catch (err) {
    toast.error(err.response?.data?.message || '移除失敗')
  }
}

async function addToCart(productId) {
  if (!user.value?.id) { toast.error('請先登入'); return }
  try {
    await cartAPI.addToCart(user.value.id, { productId, quantity: 1 })
    toast.success('已加入購物車')
  } catch (err) {
    toast.error(err.response?.data?.message || '加入失敗')
  }
}

onMounted(loadWishlist)
</script>
