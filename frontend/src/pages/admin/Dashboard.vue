<template>
  <v-container class="py-6" style="max-width: 1200px">
    <h1 class="text-h4 font-weight-bold mb-6">管理員儀表板</h1>

    <v-row>
      <v-col v-for="stat in stats" :key="stat.title" cols="12" sm="6" md="3">
        <v-card height="100%">
          <v-card-text>
            <div class="d-flex align-center">
              <v-avatar :color="stat.color" class="mr-4">
                <v-icon :icon="stat.icon" color="white" />
              </v-avatar>
              <div>
                <p class="text-h4 font-weight-bold mb-0">{{ stat.display }}</p>
                <p class="text-body-2 text-medium-emphasis mb-0">{{ stat.title }}</p>
              </div>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup>
const stats = [
  { title: '總用戶數', display: '1,234', icon: 'mdi-account-group', color: 'primary' },
  { title: '總訂單數', display: '567', icon: 'mdi-shopping', color: 'success' },
  { title: '商品數量', display: '89', icon: 'mdi-trending-up', color: 'warning' },
  { title: '總收入', display: 'NT$ 123,456', icon: 'mdi-currency-usd', color: 'error' },
]
</script>
