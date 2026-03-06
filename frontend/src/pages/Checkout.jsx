import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { toast } from 'react-hot-toast';
import { orderAPI, cartAPI } from '../services/api';
import { useAuthStore } from '../stores/authStore';
import { cartEvents } from '../utils/cartEvents';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardTitle, CardHeader } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { ArrowLeft, Loader2, CreditCard } from 'lucide-react';

function Checkout() {
  const { user } = useAuthStore();
  const navigate = useNavigate();
  const [cart, setCart] = useState(null);
  const [cartItems, setCartItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [formData, setFormData] = useState({
    shippingAddress: '',
    phone: user?.phone || '',
    note: ''
  });

  useEffect(() => {
    if (!user?.id) {
      toast.error('請先登入');
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

      if (!cartData?.items || cartData.items.length === 0) {
        toast.error('購物車是空的!');
        navigate('/shop');
      }

      setLoading(false);
    } catch (error) {
      console.error('載入購物車失敗:', error);
      toast.error('載入購物車失敗');
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!formData.shippingAddress.trim()) {
      toast.error('請填寫收貨地址!');
      return;
    }

    if (!formData.phone.trim()) {
      toast.error('請填寫聯絡電話!');
      return;
    }

    // 驗證台灣手機號碼格式
    const phoneRegex = /^09\d{8}$/;
    if (!phoneRegex.test(formData.phone)) {
      toast.error('請輸入正確的台灣手機號碼格式 (例如: 0912345678)');
      return;
    }

    if (!user?.id) {
      toast.error('請先登入');
      navigate('/login');
      return;
    }

    setSubmitting(true);

    try {
      // 使用查詢參數格式傳送資料
      const params = new URLSearchParams({
        userId: user.id.toString(),
        shippingAddress: formData.shippingAddress,
        phone: formData.phone,
      });

      if (formData.note) {
        params.append('note', formData.note);
      }

      const response = await orderAPI.createOrder(`?${params.toString()}`);
      const orderData = response.data?.data || response.data;

      // 清空購物車
      try {
        await cartAPI.clearCart(user.id);
        cartEvents.notify(); // 通知其他組件更新
      } catch (clearError) {
        console.error('清空購物車失敗:', clearError);
      }

      toast.success('訂單建立成功! 訂單編號: ' + (orderData.orderNumber || orderData.id));
      navigate('/orders');
    } catch (error) {
      console.error('建立訂單失敗:', error);
      toast.error(error.response?.data?.error || '建立訂單失敗');
      setSubmitting(false);
    }
  };

  if (loading) {
     return (
       <div className='container mx-auto py-8 text-center flex justify-center'>
         <Loader2 className='h-8 w-8 animate-spin' />
       </div>
     );
  }

  const total = cart?.total || cartItems.reduce((sum, item) => {
    const itemTotal = item.subtotal || (parseFloat(item.price || 0) * (item.quantity || 0));
    return sum + itemTotal;
  }, 0);

  return (
    <div className='container mx-auto py-8 px-4 max-w-4xl'>
      <Button
        variant='ghost'
        onClick={() => navigate('/shop')}
        className='mb-6 pl-0 hover:pl-2 transition-all'
      >
        <ArrowLeft className='mr-2 h-4 w-4' /> 返回商城
      </Button>

      <div className='grid gap-8 md:grid-cols-2'>
        <div>
          <h1 className='text-3xl font-bold mb-6'>結帳</h1>
          
          <Card>
            <CardHeader>
              <CardTitle>收貨信息</CardTitle>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className='space-y-6'>
                <div className='space-y-2'>
                  <Label htmlFor='shippingAddress'>收貨地址 *</Label>
                  <Textarea
                    id='shippingAddress'
                    name='shippingAddress'
                    value={formData.shippingAddress}
                    onChange={handleInputChange}
                    placeholder='請輸入詳細地址'
                    required
                  />
                </div>

                <div className='space-y-2'>
                  <Label htmlFor='phone'>聯絡電話 *</Label>
                  <Input
                    id='phone'
                    type='tel'
                    name='phone'
                    value={formData.phone}
                    onChange={handleInputChange}
                    placeholder='請輸入手機號碼 (09xxxxxxxx)'
                    required
                  />
                </div>

                <div className='space-y-2'>
                  <Label htmlFor='note'>訂單備註</Label>
                  <Textarea
                    id='note'
                    name='note'
                    value={formData.note}
                    onChange={handleInputChange}
                    placeholder='有什麼需要告訴我們的嗎?'
                  />
                </div>

                <div className='flex gap-4 pt-4'>
                  <Button
                    type='button'
                    variant='outline'
                    onClick={() => navigate('/shop')}
                    className='flex-1'
                    disabled={submitting}
                  >
                    取消
                  </Button>
                  <Button
                    type='submit'
                    className='flex-1'
                    disabled={submitting}
                  >
                    {submitting ? (
                        <>
                            <Loader2 className='mr-2 h-4 w-4 animate-spin' /> 處理中...
                        </>
                    ) : (
                        `確認結帳 ($${total.toFixed(0)})`
                    )}
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>
        </div>

        <div>
          <Card className='sticky top-6'>
            <CardHeader>
              <CardTitle>訂單摘要</CardTitle>
            </CardHeader>
            <CardContent className='space-y-4'>
              <div className='space-y-3'>
                {cartItems.map((item) => (
                  <div key={item.id} className='flex justify-between items-start text-sm'>
                    <div>
                      <span className='font-medium block'>
                        {item.productName || item.product?.name || '商品'}
                      </span>
                      <span className='text-muted-foreground text-xs'>
                           {item.quantity}
                      </span>
                    </div>
                    <span className='font-medium'>
                      
                    </span>
                  </div>
                ))}
              </div>

               <hr className='my-4 border-gray-200' />

               <div className='flex justify-between text-lg font-bold'>
                 <span>總計</span>
                 <span className='text-primary'></span>
               </div>
               
               <div className='bg-muted p-4 rounded-lg mt-4 text-sm text-muted-foreground'>
                   <div className='flex items-center mb-2'>
                       <CreditCard className='h-4 w-4 mr-2' />
                       <span className='font-medium'>付款方式</span>
                   </div>
                   <p>目前僅支援貨到付款</p>
               </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}

export default Checkout;
