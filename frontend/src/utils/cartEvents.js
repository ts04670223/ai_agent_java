// 購物車事件管理器
class CartEventManager {
  constructor() {
    this.listeners = [];
  }

  subscribe(callback) {
    this.listeners.push(callback);
    // 返回取消訂閱的函數
    return () => {
      this.listeners = this.listeners.filter(listener => listener !== callback);
    };
  }

  notify() {
    this.listeners.forEach(callback => callback());
  }
}

export const cartEvents = new CartEventManager();
