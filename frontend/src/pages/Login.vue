<template>
  <v-app>
    <v-main class="bg-grey-lighten-3">
      <v-container class="fill-height" fluid>
        <v-row align="center" justify="center">
          <v-col cols="12" sm="8" md="5" lg="4">
            <v-card elevation="4" rounded="lg">
              <v-card-title class="text-h5 text-center pt-6 pb-2">
                🛍️ 登入
              </v-card-title>

              <v-card-text>
                <v-alert v-if="error" type="error" variant="tonal" class="mb-4" closable @click:close="error = ''">
                  {{ error }}
                </v-alert>

                <v-form @submit.prevent="handleSubmit">
                  <v-text-field
                    v-model="form.username"
                    label="帳號"
                    prepend-inner-icon="mdi-account"
                    variant="outlined"
                    class="mb-3"
                    required
                    autofocus
                  />
                  <v-text-field
                    v-model="form.password"
                    label="密碼"
                    prepend-inner-icon="mdi-lock"
                    :type="showPassword ? 'text' : 'password'"
                    :append-inner-icon="showPassword ? 'mdi-eye-off' : 'mdi-eye'"
                    @click:append-inner="showPassword = !showPassword"
                    variant="outlined"
                    class="mb-4"
                    required
                  />

                  <v-btn
                    type="submit"
                    color="primary"
                    block
                    size="large"
                    :loading="loading"
                  >
                    登入
                  </v-btn>
                </v-form>

                <!-- Passkey 登入 -->
                <v-divider class="my-4">
                  <span class="text-body-2 text-medium-emphasis">或</span>
                </v-divider>
                <v-btn
                  variant="outlined"
                  block
                  prepend-icon="mdi-key"
                  @click="handlePasskeyLogin"
                  :loading="passkeyLoading"
                >
                  使用 Passkey 登入
                </v-btn>
              </v-card-text>

              <v-card-actions class="justify-center pb-4">
                <span class="text-body-2">還沒有帳號？</span>
                <RouterLink to="/register" class="text-primary text-body-2 ml-1">立即註冊</RouterLink>
              </v-card-actions>
            </v-card>
          </v-col>
        </v-row>
      </v-container>
    </v-main>
  </v-app>
</template>

<script setup>
import { ref } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'
import { useAuthStore } from '../stores/authStore.js'
import { authAPI, passkeyAPI } from '../services/api.js'

const router = useRouter()
const toast = useToast()
const authStore = useAuthStore()

const form = ref({ username: '', password: '' })
const error = ref('')
const loading = ref(false)
const passkeyLoading = ref(false)
const showPassword = ref(false)

// WebAuthn 工具函式
function base64urlToBuffer(base64url) {
  const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/')
  const padded = base64.padEnd(base64.length + ((4 - (base64.length % 4)) % 4), '=')
  const binary = atob(padded)
  const buffer = new ArrayBuffer(binary.length)
  const view = new Uint8Array(buffer)
  for (let i = 0; i < binary.length; i++) view[i] = binary.charCodeAt(i)
  return buffer
}

function bufferToBase64url(buffer) {
  const bytes = new Uint8Array(buffer)
  let str = ''
  for (const b of bytes) str += String.fromCharCode(b)
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

function prepareRequestOptions(serverOptions) {
  const pkOpts = serverOptions.publicKeyCredentialRequestOptions || serverOptions
  const prepared = { ...pkOpts }
  prepared.challenge = base64urlToBuffer(pkOpts.challenge)
  if (pkOpts.allowCredentials?.length) {
    prepared.allowCredentials = pkOpts.allowCredentials.map((c) => ({
      ...c,
      id: base64urlToBuffer(c.id),
    }))
  }
  return prepared
}

function prepareAssertionForTransport(credential) {
  return {
    id: credential.id,
    rawId: bufferToBase64url(credential.rawId),
    type: credential.type,
    response: {
      authenticatorData: bufferToBase64url(credential.response.authenticatorData),
      clientDataJSON: bufferToBase64url(credential.response.clientDataJSON),
      signature: bufferToBase64url(credential.response.signature),
      userHandle: credential.response.userHandle
        ? bufferToBase64url(credential.response.userHandle)
        : null,
    },
  }
}

async function handleSubmit() {
  if (!form.value.username || !form.value.password) {
    error.value = '請輸入帳號和密碼'
    return
  }

  loading.value = true
  error.value = ''

  try {
    const response = await authAPI.login({
      username: form.value.username,
      password: form.value.password,
    })
    const { token, user } = response.data.data
    authStore.login(user, token)
    toast.success('登入成功！')
    router.push('/shop')
  } catch (err) {
    error.value = err.response?.data?.message || err.response?.data?.error || '帳號或密碼錯誤'
  } finally {
    loading.value = false
  }
}

async function handlePasskeyLogin() {
  if (!form.value.username) {
    toast.warning('請先輸入帳號')
    return
  }
  passkeyLoading.value = true
  try {
    const optResponse = await passkeyAPI.getAuthOptions(form.value.username)
    const options = optResponse.data
    const preparedOptions = prepareRequestOptions(options)
    const credential = await navigator.credentials.get({ publicKey: preparedOptions })
    const assertionData = prepareAssertionForTransport(credential)
    const verifyResponse = await passkeyAPI.verifyAuthentication({
      username: form.value.username,
      credential: assertionData,
    })
    const { token, user } = verifyResponse.data.data
    authStore.login(user, token)
    toast.success('Passkey 登入成功！')
    router.push('/shop')
  } catch (err) {
    toast.error(err.response?.data?.message || 'Passkey 登入失敗')
  } finally {
    passkeyLoading.value = false
  }
}
</script>
