import React, { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../stores/authStore';
import { aiAPI } from '../services/api';
import '../styles/AiAssistant.css';

const MODES = [
  { id: 'chat',      label: '💬 一般對話', placeholder: '詢問任何問題…' },
  { id: 'recommend', label: '🎁 商品推薦', placeholder: '告訴我你想要什麼商品，例如：送禮、運動用品…' },
  { id: 'search',    label: '🔍 智慧搜尋', placeholder: '用自然語言搜尋商品，例如：適合夏天穿的衣服' },
];

const EXAMPLES = [
  '幫我推薦適合送媽媽的生日禮物',
  '我想買一件適合健身的衣服，預算500元以下',
  '你好，請介紹一下你自己',
  '有什麼暢銷商品嗎？',
];

const QUICK_PROMPTS = {
  chat:      ['你好', '你能做什麼？', '有什麼優惠？'],
  recommend: ['送禮推薦', '價格實惠的選擇', '熱門商品'],
  search:    ['夏季衣服', '電子產品', '生活用品'],
};

function formatTime(date) {
  return date.toLocaleTimeString('zh-TW', { hour: '2-digit', minute: '2-digit' });
}

const AiAssistant = () => {
  const navigate = useNavigate();
  const { user } = useAuthStore();
  const [mode, setMode] = useState('chat');
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [online, setOnline] = useState(null); // null=未知, true=在線, false=離線
  const messagesEndRef = useRef(null);
  const textareaRef = useRef(null);

  // 檢查 AI 服務狀態
  useEffect(() => {
    aiAPI.health()
      .then(() => setOnline(true))
      .catch(() => setOnline(false));
  }, []);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, loading]);

  const addMessage = (role, content) => {
    setMessages(prev => [...prev, { role, content, time: new Date() }]);
  };

  const buildHistory = () =>
    messages
      .filter(m => m.role !== 'error')
      .map(m => ({ role: m.role, content: m.content }));

  const handleSend = async (text) => {
    const trimmed = (text ?? input).trim();
    if (!trimmed || loading) return;

    setInput('');
    addMessage('user', trimmed);
    setLoading(true);

    try {
      let aiContent = '';

      if (mode === 'chat') {
        const res = await aiAPI.chat(trimmed, buildHistory());
        aiContent = res.data?.data?.reply || res.data?.reply || '（無回覆）';

      } else if (mode === 'recommend') {
        const res = await aiAPI.recommend(trimmed);
        const d = res.data?.data || res.data;
        if (d?.recommendations?.length > 0) {
          aiContent = d.analysis + '\n\n';
          aiContent += d.recommendations
            .map((r, i) => `**${i + 1}. ${r.name}**（${r.category}）\n${r.reason || ''}`)
            .join('\n\n');
        } else {
          aiContent = d?.analysis || '找不到符合的商品推薦。';
        }

      } else if (mode === 'search') {
        const res = await aiAPI.searchAssist(trimmed);
        const d = res.data?.data || res.data;
        if (d?.products?.length > 0) {
          aiContent = `找到 ${d.products.length} 項商品：\n\n`;
          aiContent += d.products
            .map((p, i) => `**${i + 1}. ${p.name}** — NT$${p.price}\n${p.description || ''}`)
            .join('\n\n');
        } else {
          aiContent = d?.message || '未找到符合的商品。';
        }
      }

      addMessage('assistant', aiContent);
      setOnline(true);
    } catch (err) {
      const status = err?.response?.status;
      const isTimeout = err?.code === 'ECONNABORTED' || err?.code === 'ERR_CANCELED' || !err?.response;
      let errMsg;
      if (status === 503 || status === 502) {
        errMsg = 'LLM 服務暫時無法使用，請確認 Ollama 是否正常運行。';
        setOnline(false);
      } else if (status === 504) {
        errMsg = '請求逾時（網關超時），請稍後再試。';
      } else if (isTimeout) {
        errMsg = '請求逾時（模型處理較慢），請稍後再試。若問題持續，可重新整理頁面。';
      } else if (status === 400) {
        errMsg = '請求格式錯誤，請重新整理頁面後再試。';
      } else {
        errMsg = `AI 服務發生錯誤（${status ?? '網路錯誤'}），請稍後再試。`;
      }
      console.error('[AI Chat Error]', { status, code: err?.code, message: err?.message });
      addMessage('error', errMsg);
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const handleTextareaInput = (e) => {
    const el = e.target;
    el.style.height = 'auto';
    el.style.height = Math.min(el.scrollHeight, 120) + 'px';
    setInput(el.value);
  };

  const currentMode = MODES.find(m => m.id === mode);

  return (
    <div className="ai-container">
      {/* 頭部 */}
      <div className="ai-header">
        <div className="ai-header-icon">🤖</div>
        <div className="ai-header-info" style={{ flex: 1 }}>
          <h2>AI 購物助手</h2>
          <p>
            <span className={`ai-status-dot ${online === false ? 'offline' : ''}`} />
            {online === null ? '檢查中…' : online ? 'Ollama 服務正常' : '服務離線'}
          </p>
        </div>
        <button
          onClick={() => navigate('/shop')}
          style={{
            border: 'none', background: 'none', cursor: 'pointer',
            fontSize: 20, color: '#6b7280', padding: '4px 8px'
          }}
          title="返回商店"
        >✕</button>
      </div>

      {/* 模式選擇 */}
      <div className="ai-mode-bar">
        {MODES.map(m => (
          <button
            key={m.id}
            className={`ai-mode-btn ${mode === m.id ? 'active' : ''}`}
            onClick={() => { setMode(m.id); setInput(''); }}
          >
            {m.label}
          </button>
        ))}
      </div>

      {/* 訊息區 */}
      <div className="ai-messages">
        {messages.length === 0 ? (
          <div className="ai-empty">
            <div className="ai-empty-icon">🛍️</div>
            <h3>歡迎使用 AI 購物助手</h3>
            <p>您可以詢問商品推薦、搜尋商品，或與 AI 自由對話</p>
            <div className="ai-example-list">
              {EXAMPLES.map((ex, i) => (
                <button
                  key={i}
                  className="ai-example-item"
                  onClick={() => handleSend(ex)}
                >
                  💭 {ex}
                </button>
              ))}
            </div>
          </div>
        ) : (
          messages.map((msg, idx) => (
            msg.role === 'error' ? (
              <div key={idx} style={{
                alignSelf: 'center',
                background: '#fee2e2',
                color: '#b91c1c',
                padding: '8px 16px',
                borderRadius: 12,
                fontSize: 13,
                maxWidth: '80%',
                textAlign: 'center',
              }}>
                ⚠️ {msg.content}
              </div>
            ) : (
              <div key={idx} className={`ai-message ${msg.role}`}>
                <div className={`ai-avatar ${msg.role === 'assistant' ? 'bot' : 'user'}`}>
                  {msg.role === 'assistant' ? '🤖' : (user?.name?.[0] || '我')}
                </div>
                <div>
                  <div className="ai-bubble">
                    {msg.content.split(/(\*\*[^*]+\*\*)/).map((part, i) =>
                      part.startsWith('**') && part.endsWith('**')
                        ? <strong key={i}>{part.slice(2, -2)}</strong>
                        : part
                    )}
                  </div>
                  <div className="ai-bubble-time">{formatTime(msg.time)}</div>
                </div>
              </div>
            )
          ))
        )}

        {loading && (
          <div className="ai-message assistant">
            <div className="ai-avatar bot">🤖</div>
            <div className="ai-bubble">
              <div className="ai-loading-dots">
                <span/><span/><span/>
              </div>
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* 輸入區 */}
      <div className="ai-input-area">
        <div className="ai-quick-prompts">
          {QUICK_PROMPTS[mode].map((p, i) => (
            <button key={i} className="ai-quick-btn" onClick={() => handleSend(p)}>
              {p}
            </button>
          ))}
        </div>
        <div className="ai-input-row">
          <textarea
            ref={textareaRef}
            className="ai-textarea"
            rows={1}
            placeholder={currentMode.placeholder}
            value={input}
            onChange={handleTextareaInput}
            onKeyDown={handleKeyDown}
            disabled={loading}
          />
          <button
            className="ai-send-btn"
            onClick={() => handleSend()}
            disabled={!input.trim() || loading}
            title="發送 (Enter)"
          >
            ➤
          </button>
        </div>
        <p className="ai-hint">按 Enter 發送 · Shift+Enter 換行</p>
      </div>
    </div>
  );
};

export default AiAssistant;
