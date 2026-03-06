import { create } from 'zustand';
import { persist } from 'zustand/middleware';

const useCartStore = create(
  persist(
    (set, get) => ({
  items: [],
  total: 0,

  addItem: (product, quantity = 1, variantId = null) => {
    const state = get();
    const existingItemIndex = state.items.findIndex(
      item => item.product.id === product.id && item.variantId === variantId
    );

    if (existingItemIndex > -1) {
      // 更新現有商品數量
      const updatedItems = [...state.items];
      updatedItems[existingItemIndex].quantity += quantity;
      set({ items: updatedItems });
    } else {
      // 添加新商品
      const newItem = {
        id: Date.now(),
        product,
        quantity,
        variantId,
        price: product.price,
      };
      set({ items: [...state.items, newItem] });
    }

    get().calculateTotal();
  },

  removeItem: (itemId) => {
    const state = get();
    const updatedItems = state.items.filter(item => item.id !== itemId);
    set({ items: updatedItems });
    get().calculateTotal();
  },

  updateQuantity: (itemId, quantity) => {
    if (quantity <= 0) {
      get().removeItem(itemId);
      return;
    }

    const state = get();
    const updatedItems = state.items.map(item =>
      item.id === itemId ? { ...item, quantity } : item
    );
    set({ items: updatedItems });
    get().calculateTotal();
  },

  clearCart: () => {
    set({ items: [], total: 0 });
  },

  calculateTotal: () => {
    const state = get();
    const total = state.items.reduce(
      (sum, item) => sum + (item.price * item.quantity),
      0
    );
    set({ total });
  },

  getItemCount: () => {
    const state = get();
    return state.items.reduce((count, item) => count + item.quantity, 0);
  },

  getTotalPrice: () => {
    const state = get();
    return state.items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
  },
    }),
    {
      name: 'cart-storage',
      partialize: (state) => ({ items: state.items, total: state.total }),
    }
  )
);

export { useCartStore };