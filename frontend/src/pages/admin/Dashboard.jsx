import React from 'react';
import {
  Container,
  Typography,
  Grid,
  Card,
  CardContent,
  Box,
  Avatar
} from '@mui/material';
import {
  TrendingUp,
  People,
  ShoppingBag,
  AttachMoney
} from '@mui/icons-material';

export default function AdminDashboard() {
  // 這裡應該從 API 獲取真實數據
  const stats = {
    totalUsers: 1234,
    totalOrders: 567,
    totalProducts: 89,
    totalRevenue: 123456,
  };

  const StatCard = ({ title, value, icon, color }) => (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center' }}>
          <Avatar sx={{ bgcolor: color, mr: 2 }}>
            {icon}
          </Avatar>
          <Box>
            <Typography variant="h4" component="div">
              {value}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {title}
            </Typography>
          </Box>
        </Box>
      </CardContent>
    </Card>
  );

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Typography variant="h4" gutterBottom>
        管理員儀表板
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="總用戶數"
            value={stats.totalUsers}
            icon={<People />}
            color="primary.main"
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="總訂單數"
            value={stats.totalOrders}
            icon={<ShoppingBag />}
            color="success.main"
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="商品數量"
            value={stats.totalProducts}
            icon={<TrendingUp />}
            color="warning.main"
          />
        </Grid>

        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="總收入"
            value={`NT$ ${stats.totalRevenue.toLocaleString()}`}
            icon={<AttachMoney />}
            color="error.main"
          />
        </Grid>
      </Grid>
    </Container>
  );
}