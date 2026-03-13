<template>
  <div class="chat-wrapper" style="height: calc(100vh - 64px); display: flex; overflow: hidden">
    <!-- 聯絡人側邊欄 -->
    <div
      class="sidebar"
      :class="{ 'd-none': isMobile && selectedUser }"
      style="width: 280px; min-width: 280px; border-right: 1px solid rgba(0,0,0,0.12); overflow-y: auto; background: #fafafa"
    >
      <!-- 當前用戶資訊 -->
      <v-list-item
        :title="user?.name || user?.username || '用戶'"
        :subtitle="'@' + (user?.username || '')"
        class="pa-3"
      >
        <template v-slot:prepend>
          <v-avatar color="primary">
            <span class="text-white">{{ userInitial }}</span>
          </v-avatar>
        </template>
      </v-list-item>
      <v-divider />

      <!-- 聯絡人列表 -->
      <div class="pa-3">
        <p class="text-caption text-medium-emphasis mb-2">聯絡人</p>
      </div>
      <div v-if="users.length === 0" class="text-center pa-4 text-medium-emphasis text-body-2">
        沒有聯絡人
      </div>
      <v-list density="compact" nav v-else>
        <v-list-item
          v-for="contact in users"
          :key="contact.id"
          :active="selectedUser?.id === contact.id"
          color="primary"
          rounded
          class="mb-1"
          @click="handleSelectUser(contact)"
        >
          <template v-slot:prepend>
            <v-avatar color="secondary" size="36">
              <span class="text-white text-caption">
                {{ (contact?.name?.charAt(0) || contact?.username?.charAt(0) || '?').toUpperCase() }}
              </span>
            </v-avatar>
          </template>
          <template v-slot:title>
            <span class="text-body-2">{{ contact?.name || contact?.username || '未知用戶' }}</span>
          </template>
          <template v-slot:subtitle>
            <span class="text-caption">@{{ contact?.username || '' }}</span>
          </template>
          <template v-slot:append v-if="unreadCounts[contact.id] > 0">
            <v-badge :content="unreadCounts[contact.id]" color="error" />
          </template>
        </v-list-item>
      </v-list>
    </div>

    <!-- 聊天區域 -->
    <div class="flex-grow-1 d-flex flex-column" :class="{ 'd-none': isMobile && !selectedUser }">
      <!-- 聊天標題列 -->
      <div v-if="selectedUser" class="pa-3 d-flex align-center" style="border-bottom: 1px solid rgba(0,0,0,0.12)">
        <v-btn v-if="isMobile" icon size="small" variant="text" class="mr-2" @click="selectedUser = null">
          <v-icon>mdi-arrow-left</v-icon>
        </v-btn>
        <v-avatar color="secondary" size="36" class="mr-2">
          <span class="text-white text-caption">
            {{ (selectedUser?.name?.charAt(0) || selectedUser?.username?.charAt(0) || '?').toUpperCase() }}
          </span>
        </v-avatar>
        <div>
          <div class="text-body-1 font-weight-medium">{{ selectedUser?.name || selectedUser?.username }}</div>
          <div class="text-caption text-medium-emphasis">@{{ selectedUser?.username }}</div>
        </div>
      </div>

      <!-- 未選擇聯絡人 -->
      <div v-if="!selectedUser" class="d-flex align-center justify-center flex-grow-1 text-medium-emphasis">
        <div class="text-center">
          <v-icon size="64" color="grey">mdi-message-outline</v-icon>
          <p class="mt-2">請選擇聯絡人開始聊天</p>
        </div>
      </div>

      <!-- 訊息區域 -->
      <div
        v-else
        ref="messagesContainer"
        class="flex-grow-1 overflow-y-auto pa-4"
        style="background: #f5f5f5"
      >
        <div v-if="loading" class="d-flex justify-center pa-4">
          <v-progress-circular indeterminate color="primary" size="32" />
        </div>
        <div
          v-for="msg in messages"
          :key="msg.id"
          class="mb-3"
          :class="{ 'd-flex justify-end': msg.senderId === user?.id }"
        >
          <div
            class="pa-3 rounded-lg"
            style="max-width: 70%"
            :style="{
              background: msg.senderId === user?.id ? '#1976D2' : 'white',
              color: msg.senderId === user?.id ? 'white' : 'inherit',
              boxShadow: '0 1px 2px rgba(0,0,0,0.1)'
            }"
          >
            <div class="text-body-2">{{ msg.message || msg.content }}</div>
            <div class="d-flex align-center justify-end ga-1 mt-1 opacity-70" style="font-size: 11px">
              <span v-if="msg.senderId === user?.id && msg.isRead" class="text-caption">已讀</span>
              <span class="text-caption">{{ formatTime(msg.createdAt || msg.timestamp) }}</span>
            </div>
          </div>
        </div>
        <div ref="messagesEndRef" />
      </div>

      <!-- 輸入框 -->
      <div v-if="selectedUser" class="pa-3" style="border-top: 1px solid rgba(0,0,0,0.12)">
        <v-form @submit.prevent="handleSendMessage" class="d-flex ga-2">
          <v-text-field
            v-model="newMessage"
            placeholder="輸入訊息..."
            variant="outlined"
            density="compact"
            hide-details
            class="flex-grow-1"
            @keydown.enter.prevent="handleSendMessage"
          />
          <v-btn
            type="submit"
            color="primary"
            icon
            :disabled="!newMessage.trim()"
          >
            <v-icon>mdi-send</v-icon>
          </v-btn>
        </v-form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'
import { useDisplay } from 'vuetify'
import { authAPI, chatAPI } from '../services/api.js'
import { useAuthStore } from '../stores/authStore.js'

const router = useRouter()
const toast = useToast()
const authStore = useAuthStore()
const user = computed(() => authStore.user)
const userInitial = computed(() => {
  const name = user.value?.name || user.value?.username || '?'
  return name.charAt(0).toUpperCase()
})

const { smAndDown } = useDisplay()
const isMobile = computed(() => smAndDown.value)

const users = ref([])
const selectedUser = ref(null)
const messages = ref([])
const newMessage = ref('')
const loading = ref(false)
const unreadCounts = ref({})
const messagesEndRef = ref(null)
const messagesContainer = ref(null)

let mainInterval = null
let unreadInterval = null

function scrollToBottom() {
  nextTick(() => {
    messagesEndRef.value?.scrollIntoView({ behavior: 'smooth' })
  })
}

function formatTime(timestamp) {
  if (!timestamp) return ''
  return new Date(timestamp).toLocaleTimeString('zh-TW', { hour: '2-digit', minute: '2-digit' })
}

async function loadUsers() {
  try {
    const response = await authAPI.getUsers()
    const data = response.data?.data || response.data || []
    users.value = Array.isArray(data) ? data.filter(u => u.id !== user.value?.id) : []
  } catch {
    users.value = []
  }
}

async function loadUnreadCounts() {
  if (!user.value?.id) return
  try {
    const response = await chatAPI.getUnreadMessages(user.value.id)
    const msgs = response.data?.data || response.data || []
    const counts = {}
    if (Array.isArray(msgs)) {
      msgs.forEach(msg => {
        if (msg.senderId && msg.senderId !== user.value.id) {
          counts[msg.senderId] = (counts[msg.senderId] || 0) + 1
        }
      })
    }
    unreadCounts.value = counts
  } catch {}
}

async function loadMessages(showLoading = true) {
  if (!selectedUser.value) return
  if (showLoading) loading.value = true
  try {
    const response = await chatAPI.getChatHistory(user.value.id, selectedUser.value.id)
    messages.value = response.data?.data || response.data || []
    await chatAPI.markChatAsRead(user.value.id, selectedUser.value.id)
    // 標記已讀後重新載入，讓對方已讀狀態即時更新
    const response2 = await chatAPI.getChatHistory(user.value.id, selectedUser.value.id)
    messages.value = response2.data?.data || response2.data || []
    await loadUnreadCounts()
    scrollToBottom()
  } catch {}
  finally {
    if (showLoading) loading.value = false
  }
}

async function handleSelectUser(contact) {
  selectedUser.value = contact
  messages.value = []
  try {
    await chatAPI.markChatAsRead(user.value.id, contact.id)
    await loadUnreadCounts()
  } catch {}
}

async function handleSendMessage() {
  if (!newMessage.value.trim() || !selectedUser.value) return
  try {
    await chatAPI.sendMessage({
      senderId: user.value.id,
      receiverId: selectedUser.value.id,
      message: newMessage.value.trim(),
    })
    newMessage.value = ''
    await loadMessages(false)
  } catch {
    toast.error('發送失敗，請稍後再試')
  }
}

watch(selectedUser, (newUser) => {
  if (mainInterval) clearInterval(mainInterval)
  if (newUser) {
    loadMessages()
    mainInterval = setInterval(() => {
      loadMessages(false)
      loadUnreadCounts()
    }, 3000)
  }
})

onMounted(() => {
  loadUsers()
  loadUnreadCounts()
  unreadInterval = setInterval(loadUnreadCounts, 5000)
})

onUnmounted(() => {
  if (mainInterval) clearInterval(mainInterval)
  if (unreadInterval) clearInterval(unreadInterval)
})
</script>
