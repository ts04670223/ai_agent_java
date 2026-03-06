import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { authAPI, chatAPI } from '../services/api';
import { useAuthStore } from '../stores/authStore';
import '../styles/Chat.css';

function Chat() {
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();
  const [users, setUsers] = useState([]);
  const [selectedUser, setSelectedUser] = useState(null);
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [unreadCounts, setUnreadCounts] = useState({}); // 每個用戶的未讀數量
  const [isMobile, setIsMobile] = useState(false); // 檢測是否為手機
  const messagesEndRef = useRef(null);
  const intervalRef = useRef(null);

  // 檢測螢幕大小
  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth <= 768);
    };

    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  // 載入所有用戶
  useEffect(() => {
    loadUsers();
    loadUnreadCounts(); // 載入未讀數量

    // 即使沒有選擇用戶，也定期更新未讀數量
    const unreadInterval = setInterval(() => {
      loadUnreadCounts();
    }, 5000); // 每5秒更新一次

    return () => clearInterval(unreadInterval);
  }, []);

  // 自動刷新訊息和未讀數量
  useEffect(() => {
    if (selectedUser) {
      loadMessages();

      // 每3秒刷新一次訊息
      intervalRef.current = setInterval(() => {
        loadMessages(false); // false 表示靜默載入，不顯示載入動畫
        loadUnreadCounts(); // 同時更新未讀數量
      }, 3000);
    }

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [selectedUser]);

  // 自動滾動到底部
  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const loadUsers = async () => {
    try {
      const response = await authAPI.getUsers();
      // 後端返回 ApiResponse 格式: { success, message, data }
      const usersData = response.data?.data || response.data || [];
      // 過濾掉當前用戶
      setUsers(Array.isArray(usersData) ? usersData.filter(u => u.id !== user.id) : []);
    } catch (error) {
      console.error('載入用戶列表失敗:', error);
      setUsers([]);
    }
  };

  // 載入所有用戶的未讀訊息數量
  const loadUnreadCounts = async () => {
    if (!user?.id) return;
    try {
      const response = await chatAPI.getUnreadMessages(user.id);

      // 解包 ApiResponse 格式
      const unreadMessages = response.data?.data || response.data || [];

      // 統計每個發送者的未讀訊息數量
      const counts = {};
      if (Array.isArray(unreadMessages)) {
        unreadMessages.forEach(msg => {
          if (msg.senderId && msg.senderId !== user.id) {
            counts[msg.senderId] = (counts[msg.senderId] || 0) + 1;
          }
        });
      }
      setUnreadCounts(counts);
    } catch (error) {
      console.error('載入未讀訊息數量失敗:', error);
    }
  };

  const loadMessages = async (showLoading = true) => {
    if (!selectedUser) return;

    if (showLoading) setLoading(true);

    try {
      const response = await chatAPI.getChatHistory(user.id, selectedUser.id);
      setMessages(response.data);

      // 標記為已讀
      await chatAPI.markChatAsRead(user.id, selectedUser.id);

      // 立即更新未讀數量
      await loadUnreadCounts();
    } catch (error) {
      console.error('載入訊息失敗:', error);
    } finally {
      if (showLoading) setLoading(false);
    }
  };

  const handleSelectUser = async (contact) => {
    setSelectedUser(contact);
    setMessages([]);
    // 標記與該用戶的對話為已讀
    try {
      await chatAPI.markChatAsRead(user.id, contact.id);
      // 重新載入未讀數量
      await loadUnreadCounts();
    } catch (error) {
      console.error('標記已讀失敗:', error);
    }
  };

  // 返回聯絡人列表 (手機版)
  const handleBackToContacts = () => {
    setSelectedUser(null);
  };

  const handleSendMessage = async (e) => {
    e.preventDefault();

    if (!newMessage.trim() || !selectedUser) return;

    try {
      await chatAPI.sendMessage({
        senderId: user.id,
        receiverId: selectedUser.id,
        message: newMessage.trim(),
      });

      setNewMessage('');
      await loadMessages(false);
      await loadUnreadCounts(); // 更新未讀數量
    } catch (error) {
      console.error('發送訊息失敗:', error);
      toast.error('發送失敗，請稍後再試');
    }
  };

  const formatTime = (timestamp) => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('zh-TW', {
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <>
      <style>{`
        body { overflow: hidden; }
        .MuiAppBar-root { display: none !important; }
        .css-1b2brrz { padding: 0 !important; margin: 0 !important; }
        .MuiContainer-root { padding: 0 !important; margin: 0 !important; max-width: none !important; }
      `}</style>
      <div className="chat-container" style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        zIndex: 1300,
        margin: 0,
        borderRadius: 0
      }}>
        {/* 側邊欄 */}
        <div style={{ top: 0 }} className={`sidebar ${isMobile && selectedUser ? 'mobile-hidden' : ''}`}>
          <div className="sidebar-header">
            <div className="user-info">
              <div className="user-avatar">{user?.name?.charAt(0) || user?.username?.charAt(0) || '?'}</div>
              <div>
                <div className="user-name">{user?.name || user?.username || '用戶'}</div>
                <div className="user-username">@{user?.username || ''}</div>
              </div>
            </div>
            <div className="header-buttons">
              <button className="btn-shop" onClick={() => navigate('/shop')}>
                🛍️ 商城
              </button>
              <button className="btn-logout" onClick={handleLogout}>
                登出
              </button>
            </div>
          </div>

          <div className="contacts-list">
            <h3>聯絡人</h3>
            {users.length === 0 ? (
              <div className="empty-contacts">沒有聯絡人</div>
            ) : (
              users.map((contact) => (
                <div
                  key={contact.id}
                  className={`contact-item ${selectedUser?.id === contact.id ? 'active' : ''}`}
                  onClick={() => handleSelectUser(contact)}
                >
                  <div className="contact-avatar">
                    {contact?.name?.charAt(0) || contact?.username?.charAt(0) || '?'}
                  </div>
                  <div className="contact-info">
                    <div className="contact-name">{contact?.name || contact?.username || '未知用戶'}</div>
                    <div className="contact-username">@{contact?.username || ''}</div>
                  </div>
                  {unreadCounts[contact.id] > 0 && (
                    <div className="unread-badge" title={`${unreadCounts[contact.id]} 則未讀訊息`}>
                      {unreadCounts[contact.id]}
                    </div>
                  )}
                </div>
              ))
            )}
          </div>
        </div>

        {/* 聊天區域 */}
        <div className="chat-area">
          {selectedUser ? (
            <>
              <div className="chat-header">
                {isMobile && (
                  <button className="back-button" onClick={handleBackToContacts} title="返回聯絡人列表">
                    ←
                  </button>
                )}
                <div className="chat-avatar">
                  {selectedUser?.name?.charAt(0) || selectedUser?.username?.charAt(0) || '?'}
                </div>
                <div className="chat-info">
                  <h3>{selectedUser?.name || selectedUser?.username || '未知用戶'}</h3>
                  <p>@{selectedUser?.username || ''}</p>
                </div>
              </div>

              <div className="messages-container">
                {loading && messages.length === 0 ? (
                  <div className="loading">載入中...</div>
                ) : messages.length === 0 ? (
                  <div className="empty-state">
                    <div className="empty-icon">💬</div>
                    <p>還沒有訊息，開始聊天吧！</p>
                  </div>
                ) : (
                  <>
                    {messages.map((msg) => (
                      <div
                        key={msg.id}
                        className={`message ${msg.senderId === user.id ? 'sent' : 'received'}`}
                      >
                        <div className="message-content">
                          <div className="message-text">{msg.message}</div>
                          <div className="message-footer">
                            <span className="message-time">{formatTime(msg.timestamp)}</span>
                            {msg.senderId === user.id && (
                              <span className={`read-status ${msg.isRead ? 'read' : 'unread'}`}>
                                {msg.isRead ? '已讀' : '未讀'}
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    ))}
                    <div ref={messagesEndRef} />
                  </>
                )}
              </div>

              <form className="input-area" onSubmit={handleSendMessage}>
                <input
                  type="text"
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  placeholder="輸入訊息..."
                  disabled={loading}
                />
                <button type="submit" disabled={!newMessage.trim() || loading}>
                  發送
                </button>
              </form>
            </>
          ) : (
            <div className="empty-chat">
              <div className="empty-icon">💬</div>
              <h3>{isMobile ? '開始聊天' : '選擇一個聯絡人'}</h3>
              <p>{isMobile ? '從左側選單選擇聯絡人開始對話' : '從左側選擇一個聯絡人開始聊天'}</p>
            </div>
          )}
        </div>
      </div>
    </>
  );
}

export default Chat;
