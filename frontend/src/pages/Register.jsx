import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { useAuthStore } from '../stores/authStore';
import { authAPI } from '../services/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import '../styles/Auth.css';

function Register() {
  const [formData, setFormData] = useState({
    username: '',
    password: '',
    confirmPassword: '',
    firstName: '',
    lastName: '',
    email: '',
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { login } = useAuthStore();

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    // 驗證密碼
    if (formData.password !== formData.confirmPassword) {
      setError('兩次輸入的密碼不一致');
      return;
    }

    if (formData.password.length < 6) {
      setError('密碼長度至少6個字符');
      return;
    }

    setLoading(true);

    try {
      const { confirmPassword, ...registerData } = formData;
      await authAPI.register(registerData);

      toast.success('註冊成功！正在為您登入...');

      // 註冊成功後自動登入
      const loginResponse = await authAPI.login({
        username: formData.username,
        password: formData.password,
      });

      // 後端返回格式: { success: true, data: { token: "...", user: {...} } }
      const { token, user } = loginResponse.data.data;
      login(user, token);
      navigate('/shop');
    } catch (err) {
      const errorMessage = err.response?.data?.message || err.response?.data?.error || '註冊失敗，請稍後再試';
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
          <p className="text-sm text-muted-foreground">建立新帳號</p>
        </CardHeader>
        <CardContent>
          {error && (
            <Alert variant="destructive" className="mb-4">
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="username">用戶名</Label>
              <Input
                id="username"
                name="username"
                type="text"
                placeholder="請輸入用戶名"
                required
                value={formData.username}
                onChange={handleChange}
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="email">電子郵件</Label>
              <Input
                id="email"
                name="email"
                type="email"
                placeholder="請輸入電子郵件"
                required
                value={formData.email}
                onChange={handleChange}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="firstName">名字</Label>
                <Input
                  id="firstName"
                  name="firstName"
                  type="text"
                  placeholder="名字"
                  value={formData.firstName}
                  onChange={handleChange}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="lastName">姓氏</Label>
                <Input
                  id="lastName"
                  name="lastName"
                  type="text"
                  placeholder="姓氏"
                  value={formData.lastName}
                  onChange={handleChange}
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">密碼</Label>
              <Input
                id="password"
                name="password"
                type="password"
                placeholder="至少6個字符"
                required
                value={formData.password}
                onChange={handleChange}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="confirmPassword">確認密碼</Label>
              <Input
                id="confirmPassword"
                name="confirmPassword"
                type="password"
                placeholder="再次輸入密碼"
                required
                value={formData.confirmPassword}
                onChange={handleChange}
              />
            </div>

            <Button className="w-full" type="submit" disabled={loading}>
              {loading ? '註冊中...' : '註冊'}
            </Button>
          </form>
        </CardContent>
        <CardFooter className="flex justify-center">
          <div className="text-sm text-muted-foreground">
            已經有帳號?{" "}
            <Link to="/login" className="text-primary hover:underline">
              立即登入
            </Link>
          </div>
        </CardFooter>
      </Card>
    </div>
  );
}

export default Register;
