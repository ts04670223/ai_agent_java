import { create } from 'zustand';
import { persist } from 'zustand/middleware';

const useAuthStore = create(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,

      login: (user, token) => {
        // 存儲到 localStorage
        localStorage.setItem('token', token);
        localStorage.setItem('user', JSON.stringify(user));
        
        set({
          user,
          token,
          isAuthenticated: true,
          isLoading: false,
        });
      },

      // 舊的 login 方法重命名為 loginWithCredentials
      loginWithCredentials: async (credentials) => {
        set({ isLoading: true });
        try {
          // 動態導入 API
          const { default: api } = await import('../services/api');
          const response = await api.post('/auth/login', credentials);
          const { token, user } = response.data;
          
          // 存儲到 localStorage
          localStorage.setItem('token', token);
          localStorage.setItem('user', JSON.stringify(user));
          
          set({
            user,
            token,
            isAuthenticated: true,
            isLoading: false,
          });
          
          return { success: true };
        } catch (error) {
          set({ isLoading: false });
          return {
            success: false,
            error: error.response?.data?.message || '登入失敗',
          };
        }
      },

      register: async (userData) => {
        set({ isLoading: true });
        try {
          const { default: api } = await import('../services/api');
          const response = await api.post('/auth/register', userData);
          const { token, user } = response.data;
          
          // 存儲到 localStorage
          localStorage.setItem('token', token);
          localStorage.setItem('user', JSON.stringify(user));
          
          set({
            user,
            token,
            isAuthenticated: true,
            isLoading: false,
          });
          
          return { success: true };
        } catch (error) {
          set({ isLoading: false });
          return {
            success: false,
            error: error.response?.data?.message || '註冊失敗',
          };
        }
      },

      logout: () => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        set({
          user: null,
          token: null,
          isAuthenticated: false,
        });
      },

      // 初始化認證狀態
      initializeAuth: () => {
        const token = localStorage.getItem('token');
        const userStr = localStorage.getItem('user');
        
        if (token && userStr) {
          try {
            const user = JSON.parse(userStr);
            set({
              user,
              token,
              isAuthenticated: true,
            });
          } catch (error) {
            // JSON 解析失敗，清除無效數據
            localStorage.removeItem('token');
            localStorage.removeItem('user');
          }
        }
      },

      // 更新用戶信息
      updateUser: (userData) => {
        const updatedUser = { ...get().user, ...userData };
        localStorage.setItem('user', JSON.stringify(updatedUser));
        set({ user: updatedUser });
      },

      // 檢查認證狀態
      checkAuth: async () => {
        const token = localStorage.getItem('token');
        if (!token) {
          return false;
        }

        try {
          const { default: api } = await import('../services/api');
          const response = await api.get('/auth/me');
          const user = response.data;
          
          set({ user, isAuthenticated: true });
          localStorage.setItem('user', JSON.stringify(user));
          return true;
        } catch (error) {
          get().logout();
          return false;
        }
      },

      isLoading: false,
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        token: state.token,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);

export { useAuthStore };