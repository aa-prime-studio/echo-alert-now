
import { AlertTriangle, Heart, Package, Shield, Smartphone, Users, Wifi, Zap } from 'lucide-react';
import { Button } from '@/components/ui/button';

const Index = () => {
  const signalTypes = [
    {
      type: '我安全',
      color: 'bg-green-500',
      icon: Shield,
      description: '告知周圍人員你目前安全無虞'
    },
    {
      type: '需要物資',
      color: 'bg-yellow-500',
      icon: Package,
      description: '需要食物、水或其他基本物資'
    },
    {
      type: '需要醫療',
      color: 'bg-red-500',
      icon: Heart,
      description: '需要醫療協助或緊急救護'
    },
    {
      type: '危險警告',
      color: 'bg-gray-900',
      icon: AlertTriangle,
      description: '警告周圍存在危險狀況'
    }
  ];

  const features = [
    {
      icon: Wifi,
      title: '完全離線運作',
      description: '不需要網路連線，透過藍牙和 Wi-Fi Direct 進行點對點通訊'
    },
    {
      icon: Users,
      title: '50-100公尺範圍',
      description: '自動發現並連接附近的 Signal-Lite 使用者'
    },
    {
      icon: Zap,
      title: '即時訊號傳遞',
      description: '四種固定狀態訊號，快速清晰地表達當前狀況'
    },
    {
      icon: Smartphone,
      title: '簡潔易用介面',
      description: '大按鈕設計，即使在緊急情況下也能快速操作'
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-blue-600 rounded-lg flex items-center justify-center">
                <Zap className="w-6 h-6 text-white" />
              </div>
              <h1 className="text-2xl font-bold text-gray-900">Signal-Lite</h1>
            </div>
            <nav className="hidden md:flex space-x-8">
              <a href="#features" className="text-gray-600 hover:text-gray-900">功能特色</a>
              <a href="#signals" className="text-gray-600 hover:text-gray-900">訊號類型</a>
              <a href="#tech" className="text-gray-600 hover:text-gray-900">技術架構</a>
            </nav>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative py-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto text-center">
          <h2 className="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
            離線應急<span className="text-blue-600">訊號系統</span>
          </h2>
          <p className="text-xl text-gray-600 mb-8 max-w-3xl mx-auto">
            當網路中斷、基地台受損時，Signal-Lite 讓你透過藍牙與 Wi-Fi Direct 
            與附近的人保持緊急聯繫。四種簡單訊號，關鍵時刻的生命線。
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button size="lg" className="bg-blue-600 hover:bg-blue-700">
              了解更多
            </Button>
            <Button size="lg" variant="outline">
              查看技術架構
            </Button>
          </div>
        </div>
      </section>

      {/* Signal Types */}
      <section id="signals" className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h3 className="text-3xl font-bold text-gray-900 mb-4">四種應急訊號</h3>
            <p className="text-lg text-gray-600">簡單明確的狀態表達，確保在緊急情況下快速溝通</p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {signalTypes.map((signal, index) => {
              const Icon = signal.icon;
              return (
                <div key={index} className="text-center p-6 rounded-xl border border-gray-200 hover:shadow-lg transition-shadow">
                  <div className={`w-20 h-20 ${signal.color} rounded-full flex items-center justify-center mx-auto mb-4`}>
                    <Icon className="w-10 h-10 text-white" />
                  </div>
                  <h4 className="text-xl font-semibold text-gray-900 mb-2">{signal.type}</h4>
                  <p className="text-gray-600">{signal.description}</p>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h3 className="text-3xl font-bold text-gray-900 mb-4">核心功能特色</h3>
            <p className="text-lg text-gray-600">專為災害應變設計的離線通訊解決方案</p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-12">
            {features.map((feature, index) => {
              const Icon = feature.icon;
              return (
                <div key={index} className="flex items-start space-x-4">
                  <div className="flex-shrink-0">
                    <div className="w-12 h-12 bg-blue-600 rounded-lg flex items-center justify-center">
                      <Icon className="w-6 h-6 text-white" />
                    </div>
                  </div>
                  <div>
                    <h4 className="text-xl font-semibold text-gray-900 mb-2">{feature.title}</h4>
                    <p className="text-gray-600">{feature.description}</p>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Technical Overview */}
      <section id="tech" className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h3 className="text-3xl font-bold text-gray-900 mb-4">技術架構</h3>
            <p className="text-lg text-gray-600">基於 iOS MultipeerConnectivity 的點對點通訊</p>
          </div>
          
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <div className="space-y-6">
              <div className="border-l-4 border-blue-600 pl-6">
                <h4 className="text-xl font-semibold text-gray-900 mb-2">通訊協定</h4>
                <p className="text-gray-600">使用 MultipeerConnectivity 框架，支援藍牙與 Wi-Fi Direct</p>
              </div>
              
              <div className="border-l-4 border-green-600 pl-6">
                <h4 className="text-xl font-semibold text-gray-900 mb-2">資料格式</h4>
                <p className="text-gray-600">CBOR 編碼，包含時間戳、狀態碼與可選位置資訊</p>
              </div>
              
              <div className="border-l-4 border-yellow-600 pl-6">
                <h4 className="text-xl font-semibold text-gray-900 mb-2">隱私保護</h4>
                <p className="text-gray-600">位置模糊化選項，無伺服器架構，資料不外流</p>
              </div>
              
              <div className="border-l-4 border-red-600 pl-6">
                <h4 className="text-xl font-semibold text-gray-900 mb-2">自動清理</h4>
                <p className="text-gray-600">訊息 24 小時自動過期，防止過時資訊誤導</p>
              </div>
            </div>
            
            <div className="bg-gray-900 rounded-xl p-8 text-white">
              <h4 className="text-xl font-semibold mb-4">技術規格</h4>
              <div className="space-y-3 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-400">平台支援:</span>
                  <span>iOS 15+</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-400">傳輸範圍:</span>
                  <span>50-100 公尺</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-400">資料大小:</span>
                  <span>512 Bytes</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-400">廣播間隔:</span>
                  <span>15 秒</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-400">加密方式:</span>
                  <span>ChaCha20-Poly1305</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-400">本地儲存:</span>
                  <span>最近 30 筆</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Use Cases */}
      <section className="py-20 bg-blue-600 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h3 className="text-3xl font-bold mb-4">應用場景</h3>
            <p className="text-lg opacity-90">在各種緊急情況下發揮關鍵作用</p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="text-center p-6">
              <div className="w-16 h-16 bg-white bg-opacity-20 rounded-full flex items-center justify-center mx-auto mb-4">
                <AlertTriangle className="w-8 h-8" />
              </div>
              <h4 className="text-xl font-semibold mb-2">自然災害</h4>
              <p className="opacity-90">地震、颱風等災害導致通訊中斷時的應急聯繫</p>
            </div>
            
            <div className="text-center p-6">
              <div className="w-16 h-16 bg-white bg-opacity-20 rounded-full flex items-center justify-center mx-auto mb-4">
                <Users className="w-8 h-8" />
              </div>
              <h4 className="text-xl font-semibold mb-2">群體活動</h4>
              <p className="opacity-90">大型活動或偏遠地區的安全狀況回報</p>
            </div>
            
            <div className="text-center p-6">
              <div className="w-16 h-16 bg-white bg-opacity-20 rounded-full flex items-center justify-center mx-auto mb-4">
                <Shield className="w-8 h-8" />
              </div>
              <h4 className="text-xl font-semibold mb-2">緊急應變</h4>
              <p className="opacity-90">基地台故障或網路管制時的替代通訊方案</p>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <div className="flex items-center justify-center space-x-3 mb-4">
              <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
                <Zap className="w-5 h-5 text-white" />
              </div>
              <h5 className="text-xl font-bold">Signal-Lite</h5>
            </div>
            <p className="text-gray-400 mb-6">離線應急訊號系統 - 關鍵時刻的生命線</p>
            <div className="border-t border-gray-800 pt-6">
              <p className="text-sm text-gray-500">
                © 2024 Signal-Lite. 開源專案，專為災害應變設計。
              </p>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Index;
