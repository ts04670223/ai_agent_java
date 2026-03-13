<template>
  <v-container class="py-6" style="max-width: 720px">
    <h1 class="text-h4 font-weight-bold mb-6">🔑 Passkey 管理</h1>

    <!-- 不支援提示 -->
    <v-card v-if="!supported">
      <v-card-text>
        <v-alert type="warning" variant="tonal">
          <template v-if="unsupportedReason === 'insecure'">
            <p class="font-weight-bold mb-2">⚠️ 需要 HTTPS 才能使用 Passkeys</p>
            <p class="text-body-2 mb-2">WebAuthn / Passkeys 只能在安全情境下運作：</p>
            <ul class="text-body-2 ml-4">
              <li>使用 <code>https://</code> 存取網站</li>
              <li>或使用 <code>localhost</code> / <code>127.0.0.1</code> 本機測試</li>
            </ul>
            <p class="text-caption mt-2">目前網址：<code>{{ currentOrigin }}</code></p>
          </template>
          <template v-else>
            您的瀏覽器不支援 WebAuthn / Passkeys。請使用 Chrome 108+、Safari 16+ 或 Firefox 119+。
          </template>
        </v-alert>
      </v-card-text>
    </v-card>

    <template v-else>
      <!-- 登錄新 Passkey -->
      <v-card class="mb-6">
        <v-card-title>登錄新的 Passkey</v-card-title>
        <v-card-text>
          <v-alert
            v-if="hasPlatformAuth === false"
            type="warning"
            variant="tonal"
            class="mb-4"
          >
            <p class="font-weight-medium mb-1">⚠️ 此裝置未偵測到生物辨識感應器</p>
            <p class="text-body-2">您仍可使用：YubiKey 等 USB 硬體安全金鑰、手機 QR Code，或 Windows Hello PIN 碼</p>
          </v-alert>
          <p v-else class="text-body-2 text-medium-emphasis mb-4">
            Passkey 使用裝置的生物辨識（指紋、臉部識別、Windows Hello）或安全金鑰代替密碼，更安全也更方便。
          </p>
          <v-text-field
            v-model="displayName"
            label="Passkey 名稱（選填）"
            placeholder="例如：我的 iPhone 15、MacBook Touch ID"
            variant="outlined"
            class="mb-4"
          />
          <v-btn
            color="primary"
            prepend-icon="mdi-fingerprint"
            :loading="registering"
            @click="handleRegister"
          >
            {{ hasPlatformAuth === false ? '登錄 Passkey（安全金鑰）' : '登錄指紋 / Windows Hello Passkey' }}
          </v-btn>
        </v-card-text>
      </v-card>

      <!-- 已登錄的 Passkeys -->
      <v-card>
        <v-card-title>已登錄的 Passkeys</v-card-title>
        <v-card-text>
          <div v-if="loading" class="d-flex justify-center pa-4">
            <v-progress-circular indeterminate color="primary" />
          </div>
          <div v-else-if="passkeys.length === 0" class="text-center text-medium-emphasis pa-4">
            尚未登錄任何 Passkey
          </div>
          <v-list v-else>
            <v-list-item
              v-for="pk in passkeys"
              :key="pk.id"
              :title="pk.name || pk.credentialId?.substring(0, 16) + '...'"
              :subtitle="'登錄時間: ' + formatDate(pk.createdAt)"
            >
              <template v-slot:prepend>
                <v-icon color="primary">mdi-key</v-icon>
              </template>
              <template v-slot:append>
                <v-btn
                  icon
                  size="small"
                  color="error"
                  variant="text"
                  @click="handleDelete(pk.credentialId || pk.id, pk.name || 'Passkey')"
                >
                  <v-icon>mdi-delete</v-icon>
                </v-btn>
              </template>
            </v-list-item>
          </v-list>
        </v-card-text>
      </v-card>
    </template>
  </v-container>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useToast } from 'vue-toastification'
import { useAuthStore } from '../stores/authStore.js'
import { passkeyAPI } from '../services/api.js'

const toast = useToast()
const authStore = useAuthStore()
const user = computed(() => authStore.user)
const isAuthenticated = computed(() => authStore.isAuthenticated)

const passkeys = ref([])
const loading = ref(false)
const registering = ref(false)
const displayName = ref('')
const supported = ref(true)
const unsupportedReason = ref('')
const hasPlatformAuth = ref(null)
const currentOrigin = ref(window.location.origin)

// WebAuthn 工具函式
function bufferToBase64url(buffer) {
  const bytes = new Uint8Array(buffer)
  let str = ''
  for (const b of bytes) str += String.fromCharCode(b)
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

function base64urlToBuffer(base64url) {
  const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/')
  const padded = base64.padEnd(base64.length + ((4 - (base64.length % 4)) % 4), '=')
  const binary = atob(padded)
  const buffer = new ArrayBuffer(binary.length)
  const view = new Uint8Array(buffer)
  for (let i = 0; i < binary.length; i++) view[i] = binary.charCodeAt(i)
  return buffer
}

function prepareCredentialForTransport(credential) {
  const obj = {
    id: credential.id,
    rawId: bufferToBase64url(credential.rawId),
    type: credential.type,
    response: {},
  }
  for (const key of Object.keys(credential.response)) {
    const val = credential.response[key]
    if (val instanceof ArrayBuffer) {
      obj.response[key] = bufferToBase64url(val)
    }
  }
  if (typeof credential.response.getTransports === 'function') {
    obj.response.transports = credential.response.getTransports()
  }
  if (typeof credential.response.getAuthenticatorData === 'function') {
    obj.response.authenticatorData = bufferToBase64url(credential.response.getAuthenticatorData())
  }
  if (typeof credential.response.getPublicKey === 'function') {
    const pk = credential.response.getPublicKey()
    if (pk) obj.response.publicKey = bufferToBase64url(pk)
  }
  if (typeof credential.response.getPublicKeyAlgorithm === 'function') {
    obj.response.publicKeyAlgorithm = credential.response.getPublicKeyAlgorithm()
  }
  return obj
}

function prepareCreationOptions(options) {
  const prepared = { ...options }
  prepared.challenge = base64urlToBuffer(options.challenge)
  prepared.user = { ...options.user, id: base64urlToBuffer(options.user.id) }
  if (options.excludeCredentials) {
    prepared.excludeCredentials = options.excludeCredentials.map(c => ({
      ...c, id: base64urlToBuffer(c.id),
    }))
  }
  return prepared
}

function formatDate(dateStr) {
  if (!dateStr) return ''
  return new Date(dateStr).toLocaleString('zh-TW')
}

async function loadPasskeys() {
  if (!isAuthenticated.value) return
  loading.value = true
  try {
    const res = await passkeyAPI.listPasskeys()
    passkeys.value = res.data?.data || res.data || []
  } catch {}
  finally {
    loading.value = false
  }
}

async function handleRegister() {
  if (!user.value?.username) return
  registering.value = true
  try {
    const name = displayName.value || `${user.value.username} 的 Passkey`
    const startRes = await passkeyAPI.startRegistration(user.value.username, name)
    const creationOptions = prepareCreationOptions(startRes.data?.data || startRes.data)
    const credential = await navigator.credentials.create({ publicKey: creationOptions })
    if (!credential) { toast.error('未能取得驗證器回應，請再試一次'); return }
    const credJson = JSON.stringify(prepareCredentialForTransport(credential))
    await passkeyAPI.finishRegistration(user.value.username, name, credJson)
    toast.success('Passkey 已成功登錄！')
    displayName.value = ''
    await loadPasskeys()
  } catch (err) {
    if (err.name === 'NotAllowedError') {
      toast.error('使用者取消了生物辨識驗證')
    } else if (err.name === 'InvalidStateError') {
      toast.error('此裝置已有相同的 Passkey，請先刪除舊的再重新登錄')
    } else {
      toast.error(err.response?.data?.message || err.message || 'Passkey 登錄失敗')
    }
  } finally {
    registering.value = false
  }
}

async function handleDelete(credentialId, name) {
  if (!confirm(`確定要刪除「${name}」嗎？`)) return
  try {
    await passkeyAPI.deletePasskey(credentialId)
    toast.success('Passkey 已刪除')
    await loadPasskeys()
  } catch (err) {
    toast.error(err.response?.data?.message || '刪除失敗')
  }
}

onMounted(() => {
  if (!window.isSecureContext) {
    supported.value = false
    unsupportedReason.value = 'insecure'
    return
  }
  if (!window.PublicKeyCredential) {
    supported.value = false
    unsupportedReason.value = 'browser'
    return
  }
  window.PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable?.()
    .then(val => { hasPlatformAuth.value = val })
    .catch(() => { hasPlatformAuth.value = false })
  loadPasskeys()
})
</script>
