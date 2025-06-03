
export interface SignalMessage {
  id: string;
  type: 'safe' | 'supplies' | 'medical' | 'danger';
  timestamp: number;
  deviceName: string;
  location?: { lat: number; lng: number };
}

export class WebRTCService {
  private peerConnection: RTCPeerConnection | null = null;
  private dataChannel: RTCDataChannel | null = null;
  private onMessageCallback: ((message: SignalMessage) => void) | null = null;
  private onConnectionStateChange: ((state: string) => void) | null = null;

  constructor() {
    this.initializePeerConnection();
  }

  private initializePeerConnection() {
    const configuration = {
      iceServers: [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' }
      ]
    };

    this.peerConnection = new RTCPeerConnection(configuration);
    
    this.peerConnection.onconnectionstatechange = () => {
      if (this.peerConnection) {
        this.onConnectionStateChange?.(this.peerConnection.connectionState);
      }
    };

    this.peerConnection.ondatachannel = (event) => {
      const channel = event.channel;
      channel.onmessage = (event) => {
        try {
          const message: SignalMessage = JSON.parse(event.data);
          this.onMessageCallback?.(message);
        } catch (error) {
          console.error('Failed to parse message:', error);
        }
      };
    };

    // Create data channel for sending messages
    this.dataChannel = this.peerConnection.createDataChannel('signals', {
      ordered: true
    });

    this.dataChannel.onopen = () => {
      console.log('Data channel opened');
    };
  }

  onMessage(callback: (message: SignalMessage) => void) {
    this.onMessageCallback = callback;
  }

  onConnectionChange(callback: (state: string) => void) {
    this.onConnectionStateChange = callback;
  }

  async sendSignal(type: SignalMessage['type'], deviceName: string, location?: { lat: number; lng: number }) {
    if (this.dataChannel && this.dataChannel.readyState === 'open') {
      const message: SignalMessage = {
        id: crypto.randomUUID(),
        type,
        timestamp: Date.now(),
        deviceName,
        location
      };

      this.dataChannel.send(JSON.stringify(message));
      return message;
    } else {
      // For demo purposes, simulate receiving our own message
      const message: SignalMessage = {
        id: crypto.randomUUID(),
        type,
        timestamp: Date.now(),
        deviceName,
        location
      };
      
      // Simulate network delay
      setTimeout(() => {
        this.onMessageCallback?.(message);
      }, 500);
      
      return message;
    }
  }

  // Simulate discovering and connecting to nearby devices
  async simulateNearbyConnection() {
    // In a real implementation, this would handle WebRTC signaling
    // For demo, we'll just change connection state
    setTimeout(() => {
      this.onConnectionStateChange?.('connected');
    }, 1000);
  }

  disconnect() {
    if (this.dataChannel) {
      this.dataChannel.close();
    }
    if (this.peerConnection) {
      this.peerConnection.close();
    }
  }
}
