
import React, { useState, useEffect } from 'react';
import { Send, Trash2, Clock, Users } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface ChatMessage {
  id: string;
  message: string;
  deviceName: string;
  timestamp: number;
  isOwn?: boolean;
}

export const ChatRoom: React.FC = () => {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [deviceName] = useState(`Device-${Math.random().toString(36).substr(2, 6)}`);

  // 24小時自動刪除訊息
  useEffect(() => {
    const interval = setInterval(() => {
      const twentyFourHoursAgo = Date.now() - (24 * 60 * 60 * 1000);
      setMessages(prev => prev.filter(m => m.timestamp > twentyFourHoursAgo));
    }, 60000); // 每分鐘檢查一次

    return () => clearInterval(interval);
  }, []);

  const sendMessage = () => {
    if (!newMessage.trim()) return;

    const message: ChatMessage = {
      id: crypto.randomUUID(),
      message: newMessage.trim(),
      deviceName,
      timestamp: Date.now(),
      isOwn: true
    };

    setMessages(prev => [message, ...prev].slice(0, 50)); // 最多保留50條訊息
    setNewMessage('');

    // 模擬接收到其他人的回應
    setTimeout(() => {
      const responses = [
        '收到！',
        '了解狀況',
        '正在前往',
        '需要更多資訊',
        '已通知相關單位'
      ];
      
      const randomResponse = responses[Math.floor(Math.random() * responses.length)];
      const responseMessage: ChatMessage = {
        id: crypto.randomUUID(),
        message: randomResponse,
        deviceName: `救援隊-${Math.random().toString(36).substr(2, 3).toUpperCase()}`,
        timestamp: Date.now(),
        isOwn: false
      };
      
      setMessages(prev => [responseMessage, ...prev].slice(0, 50));
    }, 1000 + Math.random() * 3000);
  };

  const clearMessages = () => {
    setMessages([]);
  };

  const formatTime = (timestamp: number) => {
    const now = Date.now();
    const diff = now - timestamp;
    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(diff / (1000 * 60 * 60));
    
    if (hours > 0) {
      return `${hours}小時前`;
    } else if (minutes > 0) {
      return `${minutes}分鐘前`;
    } else {
      return '剛剛';
    }
  };

  return (
    <div className="bg-white rounded-lg shadow h-full flex flex-col">
      <div className="p-4 border-b flex-shrink-0">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <Users className="w-5 h-5 text-blue-600" />
            <h3 className="font-semibold text-gray-900">應急聊天室</h3>
            <span className="text-sm text-gray-500">({messages.length})</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="flex items-center space-x-1 text-xs text-gray-500">
              <Clock className="w-4 h-4" />
              <span>24小時自動清除</span>
            </div>
            <Button
              variant="ghost"
              size="sm"
              onClick={clearMessages}
              className="text-red-600 hover:text-red-700"
            >
              <Trash2 className="w-4 h-4" />
            </Button>
          </div>
        </div>
      </div>

      {/* 訊息列表 - 自適應高度 */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {messages.length === 0 ? (
          <div className="text-center text-gray-500 py-8">
            <Users className="w-12 h-12 mx-auto mb-4 opacity-50" />
            <p>目前沒有訊息</p>
            <p className="text-sm mt-1">發送第一條訊息開始對話</p>
          </div>
        ) : (
          messages.map((msg) => (
            <div key={msg.id} className={`flex ${msg.isOwn ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-xs lg:max-w-md px-4 py-2 rounded-lg ${
                msg.isOwn 
                  ? 'bg-blue-600 text-white' 
                  : 'bg-gray-200 text-gray-900'
              }`}>
                <div className="flex items-center space-x-2 mb-1">
                  <span className={`font-medium text-sm ${
                    msg.isOwn ? 'text-blue-100' : 'text-gray-600'
                  }`}>
                    {msg.isOwn ? '我' : msg.deviceName}
                  </span>
                  <span className={`text-xs ${
                    msg.isOwn ? 'text-blue-200' : 'text-gray-500'
                  }`}>
                    {formatTime(msg.timestamp)}
                  </span>
                </div>
                <p className="break-words">{msg.message}</p>
              </div>
            </div>
          ))
        )}
      </div>

      {/* 發送訊息 */}
      <div className="p-4 border-t flex-shrink-0">
        <div className="flex space-x-2">
          <input
            type="text"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
            placeholder="輸入訊息..."
            className="flex-1 p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            maxLength={200}
          />
          <Button
            onClick={sendMessage}
            disabled={!newMessage.trim()}
            className="bg-blue-600 hover:bg-blue-700"
          >
            <Send className="w-4 h-4" />
          </Button>
        </div>
        <p className="text-xs text-gray-500 mt-2">
          訊息會在24小時後自動刪除 • 最多顯示50條訊息
        </p>
      </div>
    </div>
  );
};
