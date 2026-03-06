import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { toast } from 'react-hot-toast';
import { cartAPI } from '../services/api';
import { useAuthStore } from '../stores/authStore';
import { cartEvents } from '../utils/cartEvents';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardTitle } from '@/components/ui/card';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Plus, Minus, Trash2, ShoppingCart } from 'lucide-react';

export default function Cart() {
  const navigate = useNavigate();
  const { user } = useAuthStore();
  const [cart, setCart] = useState(null);
  const [cartItems, setCartItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openClearCartDialog, setOpenClearCartDialog] = useState(false);

  useEffect(() => {
    if (!user?.id) {
      navigate('/login');
      return;
    }
    loadCart();
  }, []);

  const loadCart = async () => {
    if (!user?.id) return;

    try {
      const response = await cartAPI.getCart(user.id);
      const cartData = response.data?.data || response.data;
      setCart(cartData);
      setCartItems(cartData?.items || []);
      setLoading(false);
    } catch (error) {
      console.error('載入購物車失敗:', error);
      toast.error('載入購物車失敗');
      setLoading(false);
    }
  };

  const handleQuantityChange = async (itemId, newQuantity) => {
    if (newQuantity < 1) {
      await handleRemoveItem(itemId);
      return;
    }

    try {
      await cartAPI.updateCartItem(user.id, itemId, newQuantity);
      await loadCart();
      cartEvents.notify();
      toast.success('數量已更新');
    } catch (error) {
      console.error('更新數量失敗:', error);
      toast.error(error.response?.data?.error || '更新失敗');
    }
  };

  const handleRemoveItem = async (itemId) => {
    try {
      await cartAPI.removeFromCart(user.id, itemId);
      await loadCart();
      cartEvents.notify();
      toast.success('已從購物車移除');
    } catch (error) {
      console.error('移除失敗:', error);
      toast.error('移除失敗');
    }
  };

  const handleClearCart = async () => {
    setOpenClearCartDialog(false);

    try {
      await cartAPI.clearCart(user.id);
      await loadCart();
      cartEvents.notify();
      toast.success('購物車已清空');
    } catch (error) {
      console.error('清空購物車失敗:', error);
      toast.error('清空購物車失敗');
    }
  };

  const handleCheckout = () => {
    if (cartItems.length === 0) {
      toast.error('購物車是空的!');
      return;
    }
    navigate('/checkout');
  };

  if (loading) {
    return (
      <div className='container mx-auto py-8 text-center'>
        <h2 className='text-xl font-medium'>載入中...</h2>
      </div>
    );
  }

  if (!cartItems || cartItems.length === 0) {
    return (
      <div className='container mx-auto py-8 text-center max-w-2xl'>
        <h1 className='text-3xl font-bold mb-4'>購物車是空的</h1>
        <p className='text-gray-500 mb-8'>
          快去挑選您喜歡的商品吧！
        </p>
        <Button
          size='lg'
          onClick={() => navigate('/shop')}
        >
          繼續購物
        </Button>
      </div>
    );
  }

  return (
    <div className='container mx-auto py-8 px-4'>
      <h1 className='text-3xl font-bold mb-8'>購物車</h1>

      <div className='flex flex-col md:flex-row gap-8'>
        {/* 購物車商品列表 */}
        <div className='flex-1'>
          {cartItems.map((item) => (
            <Card key={item.id} className='mb-4'>
              <CardContent className='p-4'>
                <div className='flex flex-col sm:flex-row gap-4 items-center'>
                  {/* 商品圖片 */}
                  <div className='w-[120px] h-[120px] flex-shrink-0 flex items-center justify-center bg-gray-100 rounded-md overflow-hidden'>
                    {item.product?.imageUrl ? (
                      <img
                        src={item.product.imageUrl}
                        alt={item.productName || item.product?.name}
                        className='object-contain w-full h-full'
                      />
                    ) : (
                      <div className='w-full h-full flex items-center justify-center bg-primary text-primary-foreground text-2xl font-bold'>
                        {(item.productName || item.product?.name || 'No').substring(0, 2).toUpperCase()}
                      </div>
                    )}
                  </div>

                  {/* 商品資訊 */}
                  <div className='flex-1 min-w-0 text-center sm:text-left'>
                    <h3 className='text-lg font-semibold mb-2'>
                      {item.productName || item.product?.name}
                    </h3>
                    {item.product?.category && (
                      <p className='text-sm text-gray-500'>
                        分類: {item.product.category}
                      </p>
                    )}
                    <p className='text-lg font-bold text-primary mt-2'>
                      ${parseFloat(item.price || 0).toFixed(0)}
                    </p>
                  </div>

                  {/* 數量控制 */}
                  <div className='flex items-center gap-2'>
                    <Button
                      variant='outline'
                      size='icon'
                      className='h-8 w-8'
                      onClick={() => handleQuantityChange(item.id, item.quantity - 1)}
                      disabled={item.quantity <= 1}
                    >
                      <Minus className='h-4 w-4' />
                    </Button>
                    <span className='w-8 text-center font-bold'>
                      {item.quantity}
                    </span>
                    <Button
                      variant='outline'
                      size='icon'
                      className='h-8 w-8'
                      onClick={() => handleQuantityChange(item.id, item.quantity + 1)}
                    >
                      <Plus className='h-4 w-4' />
                    </Button>
                  </div>

                  {/* 小計和刪除 */}
                  <div className='flex flex-col items-center min-w-[100px] gap-2'>
                    <p className='text-lg font-semibold'>
                      ${parseFloat(item.subtotal || (item.price * item.quantity) || 0).toFixed(0)}
                    </p>
                    <Button
                      variant='destructive'
                      size='icon'
                      className='h-8 w-8'
                      onClick={() => handleRemoveItem(item.id)}
                    >
                      <Trash2 className='h-4 w-4' />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* 訂單摘要 */}
        <div className='md:w-1/3'>
          <Card className='sticky top-20'>
            <CardContent className='p-6'>
              <CardTitle className='mb-4 text-xl'>訂單摘要</CardTitle>

              <div className='space-y-2 mb-4'>
                {cartItems.map((item) => (
                  <div key={item.id} className='flex justify-between text-sm'>
                    <span>
                      {item.productName || item.product?.name} x {item.quantity}
                    </span>
                    <span>
                      ${parseFloat(item.subtotal || (item.price * item.quantity) || 0).toFixed(0)}
                    </span>
                  </div>
                ))}
              </div>

              <hr className='my-4 border-gray-200' />

              <div className='flex justify-between mb-2'>
                <span>小計</span>
                <span>
                  ${parseFloat(cart?.total || 0).toFixed(0)}
                </span>
              </div>

              <div className='flex justify-between mb-2'>
                <span>運費</span>
                <span>$60.00</span>
              </div>

              <hr className='my-4 border-gray-200' />

              <div className='flex justify-between mb-6 text-lg font-bold'>
                <span>總計</span>
                <span className='text-primary'>
                  ${(parseFloat(cart?.total || 0) + 60).toFixed(0)}
                </span>
              </div>

              <div className='space-y-3'>
                <Button
                  className='w-full'
                  size='lg'
                  onClick={handleCheckout}
                >
                  <ShoppingCart className='mr-2 h-4 w-4' /> 結帳
                </Button>

                <Button
                  variant='outline'
                  className='w-full text-red-500 hover:text-red-600 hover:bg-red-50 border-red-200 hover:border-red-300'
                  onClick={() => setOpenClearCartDialog(true)}
                >
                  清空購物車
                </Button>

                <Button
                  variant='ghost'
                  className='w-full'
                  onClick={() => navigate('/shop')}
                >
                  繼續購物
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* 清空購物車確認對話框 */}
      <Dialog open={openClearCartDialog} onOpenChange={setOpenClearCartDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>清空購物車</DialogTitle>
            <DialogDescription>
              確定要清空購物車內的所有商品嗎？此操作無法復原。
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant='outline'
              onClick={() => setOpenClearCartDialog(false)}
            >
              取消
            </Button>
            <Button
              variant='destructive'
              onClick={handleClearCart}
            >
              確定清空
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
