<template>
  <v-container class="py-6" style="max-width: 900px">
    <h1 class="text-h4 font-weight-bold mb-6">個人資料</h1>

    <div v-if="!user" class="text-center py-12">
      <p class="text-h6">請先登入</p>
    </div>

    <v-row v-else>
      <!-- 基本資料 -->
      <v-col cols="12" md="8">
        <v-card class="mb-4">
          <v-card-text>
            <div class="d-flex align-center mb-6">
              <v-avatar color="primary" size="80" class="mr-4">
                <v-img v-if="user.avatar" :src="user.avatar" />
                <span v-else class="text-white text-h5">{{ user.name?.charAt(0) || user.username?.charAt(0) || '?' }}</span>
              </v-avatar>
              <div>
                <div class="text-h5 font-weight-medium">{{ user.name || user.username }}</div>
                <div class="text-body-2 text-medium-emphasis">
                  會員等級: {{ user.memberLevel || '一般會員' }}
                </div>
              </div>
            </div>

            <v-divider class="mb-4" />

            <v-row>
              <v-col cols="12" sm="6">
                <div class="d-flex align-center mb-4">
                  <v-icon class="mr-3 text-medium-emphasis">mdi-account</v-icon>
                  <div>
                    <div class="text-caption text-medium-emphasis">姓名</div>
                    <div class="text-body-1">{{ user.name || '未設定' }}</div>
                  </div>
                </div>
              </v-col>
              <v-col cols="12" sm="6">
                <div class="d-flex align-center mb-4">
                  <v-icon class="mr-3 text-medium-emphasis">mdi-at</v-icon>
                  <div>
                    <div class="text-caption text-medium-emphasis">帳號</div>
                    <div class="text-body-1">{{ user.username }}</div>
                  </div>
                </div>
              </v-col>
              <v-col cols="12" sm="6">
                <div class="d-flex align-center mb-4">
                  <v-icon class="mr-3 text-medium-emphasis">mdi-email</v-icon>
                  <div>
                    <div class="text-caption text-medium-emphasis">電子郵件</div>
                    <div class="text-body-1">{{ user.email || '未設定' }}</div>
                  </div>
                </div>
              </v-col>
              <v-col cols="12" sm="6">
                <div class="d-flex align-center mb-4">
                  <v-icon class="mr-3 text-medium-emphasis">mdi-phone</v-icon>
                  <div>
                    <div class="text-caption text-medium-emphasis">電話</div>
                    <div class="text-body-1">{{ user.phone || '未設定' }}</div>
                  </div>
                </div>
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>
      </v-col>

      <!-- 快捷功能 -->
      <v-col cols="12" md="4">
        <v-card class="mb-4">
          <v-card-title class="text-subtitle-1">帳號安全</v-card-title>
          <v-list density="compact">
            <v-list-item
              prepend-icon="mdi-key"
              title="管理 Passkeys"
              to="/passkeys"
              nav
            >
              <template v-slot:append>
                <v-icon>mdi-chevron-right</v-icon>
              </template>
            </v-list-item>
          </v-list>
        </v-card>

        <v-card>
          <v-card-title class="text-subtitle-1">快捷功能</v-card-title>
          <v-list density="compact">
            <v-list-item prepend-icon="mdi-receipt" title="我的訂單" to="/orders" nav>
              <template v-slot:append><v-icon>mdi-chevron-right</v-icon></template>
            </v-list-item>
            <v-list-item prepend-icon="mdi-heart" title="願望清單" to="/wishlist" nav>
              <template v-slot:append><v-icon>mdi-chevron-right</v-icon></template>
            </v-list-item>
            <v-list-item prepend-icon="mdi-cart" title="購物車" to="/cart" nav>
              <template v-slot:append><v-icon>mdi-chevron-right</v-icon></template>
            </v-list-item>
          </v-list>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup>
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import { useAuthStore } from '../stores/authStore.js'

const authStore = useAuthStore()
const user = computed(() => authStore.user)
</script>
