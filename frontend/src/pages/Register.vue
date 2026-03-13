<template>
  <v-app>
    <v-main class="bg-grey-lighten-3">
      <v-container class="fill-height" fluid>
        <v-row align="center" justify="center">
          <v-col cols="12" sm="8" md="5" lg="4">
            <v-card elevation="4" rounded="lg">
              <v-card-title class="text-h5 text-center pt-6 pb-2">
                📝 建立帳號
              </v-card-title>

              <v-card-text>
                <v-alert v-if="error" type="error" variant="tonal" class="mb-4" closable @click:close="error = ''">
                  {{ error }}
                </v-alert>

                <v-form @submit.prevent="handleSubmit">
                  <v-row>
                    <v-col cols="6">
                      <v-text-field
                        v-model="form.firstName"
                        label="名字"
                        variant="outlined"
                        density="compact"
                      />
                    </v-col>
                    <v-col cols="6">
                      <v-text-field
                        v-model="form.lastName"
                        label="姓氏"
                        variant="outlined"
                        density="compact"
                      />
                    </v-col>
                  </v-row>

                  <v-text-field
                    v-model="form.username"
                    label="帳號 *"
                    prepend-inner-icon="mdi-account"
                    variant="outlined"
                    class="mb-2"
                    required
                  />
                  <v-text-field
                    v-model="form.email"
                    label="電子郵件 *"
                    prepend-inner-icon="mdi-email"
                    type="email"
                    variant="outlined"
                    class="mb-2"
                    required
                  />
                  <v-text-field
                    v-model="form.password"
                    label="密碼 *"
                    prepend-inner-icon="mdi-lock"
                    :type="showPassword ? 'text' : 'password'"
                    :append-inner-icon="showPassword ? 'mdi-eye-off' : 'mdi-eye'"
                    @click:append-inner="showPassword = !showPassword"
                    variant="outlined"
                    class="mb-2"
                    required
                    hint="至少 6 個字符"
                  />
                  <v-text-field
                    v-model="form.confirmPassword"
                    label="確認密碼 *"
                    prepend-inner-icon="mdi-lock-check"
                    :type="showPassword ? 'text' : 'password'"
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
                    建立帳號
                  </v-btn>
                </v-form>
              </v-card-text>

              <v-card-actions class="justify-center pb-4">
                <span class="text-body-2">已有帳號？</span>
                <RouterLink to="/login" class="text-primary text-body-2 ml-1">立即登入</RouterLink>
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
import { authAPI } from '../services/api.js'

const router = useRouter()
const toast = useToast()
const authStore = useAuthStore()

const form = ref({
  username: '',
  password: '',
  confirmPassword: '',
  firstName: '',
  lastName: '',
  email: '',
})
const error = ref('')
const loading = ref(false)
const showPassword = ref(false)

async function handleSubmit() {
  error.value = ''

  if (form.value.password !== form.value.confirmPassword) {
    error.value = '兩次輸入的密碼不一致'
    return
  }
  if (form.value.password.length < 6) {
    error.value = '密碼長度至少 6 個字符'
    return
  }

  loading.value = true
  try {
    const { confirmPassword, ...registerData } = form.value
    await authAPI.register(registerData)
    toast.success('註冊成功！正在為您登入...')

    const loginResponse = await authAPI.login({
      username: form.value.username,
      password: form.value.password,
    })
    const { token, user } = loginResponse.data.data
    authStore.login(user, token)
    router.push('/shop')
  } catch (err) {
    error.value = err.response?.data?.message || err.response?.data?.error || '註冊失敗，請稍後再試'
  } finally {
    loading.value = false
  }
}
</script>
