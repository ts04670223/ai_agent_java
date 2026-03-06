import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import toast from 'react-hot-toast';
import { useAuthStore } from '../stores/authStore';
import { authAPI } from '../services/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import '../styles/Auth.css';

function Login() {
  const [formData, setFormData] = useState({
    username: '',
    password: '',
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { login, isAuthenticated } = useAuthStore();

  // 如果已經登入，重定向到商店頁面
  useEffect(() => {
    if (isAuthenticated) {
      navigate('/shop');
    }
  }, [isAuthenticated, navigate]);

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const response = await authAPI.login(formData);

      // 後端返回格式: { success: true, message: "登入成功", data: { token: "...", user: {...} } }
      const loginData = response.data.data;

      // 使用 Zustand store 的 login 方法
      login(loginData.user, loginData.token);

      toast.success('登入成功！');
      navigate('/shop');
    } catch (err) {
      const errorMessage = err.response?.data?.message || err.response?.data?.error || '登入失敗，請稍後再試';
      setError(errorMessage);
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container mx-auto flex items-center justify-center min-h-[80vh] px-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl font-bold"> 現代電商</CardTitle>
          <p className="text-sm text-muted-foreground">歡迎回來</p>
        </CardHeader>
        <CardContent>
          {error && (
            <Alert variant="destructive" className="mb-4">
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="username">用戶名或電子郵件</Label>
              <Input
                id="username"
                name="username"
                type="text"
                placeholder="請輸入用戶名"
                required
                autoFocus
                value={formData.username}
                onChange={handleChange}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">密碼</Label>
              <Input
                id="password"
                name="password"
                type="password"
                placeholder="請輸入密碼"
                required
                value={formData.password}
                onChange={handleChange}
              />
            </div>
            
            <Button className="w-full" type="submit" disabled={loading}>
              {loading ? '登入中...' : '登入'}
            </Button>
          </form>
        </CardContent>
        <CardFooter className="flex justify-center">
          <div className="text-sm text-muted-foreground">
            還沒有帳號?{" "}
            <Link to="/register" className="text-primary hover:underline">
              立即註冊
            </Link>
          </div>
        </CardFooter>
      </Card>
    </div>
  );
}

export default Login;
