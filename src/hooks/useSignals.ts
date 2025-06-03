import { useState, useEffect, useCallback } from 'react';
import { WebRTCService, SignalMessage } from '@/services/webrtc';

export const useSignals = () => {
  const [webrtcService] = useState(() => new WebRTCService());
  const [messages, setMessages] = useState<SignalMessage[]>([]);
  const [connectionState, setConnectionState] = useState<string>('new');
  const [deviceName, setDeviceName] = useState(`Device-${Math.random().toString(36).substr(2, 6)}`);

  useEffect(() => {
    webrtcService.onMessage((message) => {
      setMessages(prev => {
        // Remove duplicates and keep only last 30 messages
        const filtered = prev.filter(m => m.id !== message.id);
        const updated = [message, ...filtered].slice(0, 30);
        return updated;
      });
    });

    webrtcService.onConnectionChange((state) => {
      setConnectionState(state);
    });

    // Simulate connecting to nearby devices
    webrtcService.simulateNearbyConnection();

    return () => {
      webrtcService.disconnect();
    };
  }, [webrtcService]);

  // Auto-cleanup messages older than 24 hours
  useEffect(() => {
    const interval = setInterval(() => {
      const twentyFourHoursAgo = Date.now() - (24 * 60 * 60 * 1000);
      setMessages(prev => prev.filter(m => m.timestamp > twentyFourHoursAgo));
    }, 60000); // Check every minute

    return () => clearInterval(interval);
  }, []);

  const sendSignal = useCallback(async (type: SignalMessage['type']) => {
    try {
      const message = await webrtcService.sendSignal(type, deviceName);
      console.log('Signal sent:', message);
    } catch (error) {
      console.error('Failed to send signal:', error);
    }
  }, [webrtcService, deviceName]);

  const clearMessages = useCallback(() => {
    setMessages([]);
  }, []);

  return {
    messages,
    connectionState,
    deviceName,
    setDeviceName,
    sendSignal,
    clearMessages
  };
};
