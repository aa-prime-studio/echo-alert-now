
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { useLanguage } from "@/contexts/LanguageContext";
import { useNavigate } from "react-router-dom";
import { Smartphone, Users, Zap, Monitor, ShoppingCart, Package } from "lucide-react";

const Index = () => {
  const { t, language, setLanguage } = useLanguage();
  const navigate = useNavigate();
  const [currentStep, setCurrentStep] = useState(0);

  const handleStartApp = () => {
    navigate("/app");
  };

  const steps = [
    {
      icon: Monitor,
      title: language === 'zh' ? "打開應用程式" : "Open the App",
      description: language === 'zh' ? "簡單快速的開始使用我們的緊急通訊系統" : "Quick and easy start with our emergency communication system"
    },
    {
      icon: ShoppingCart,
      title: language === 'zh' ? "選擇功能" : "Choose Features", 
      description: language === 'zh' ? "配對相關的功能或圖像，或簡化視覺效果" : "Pair with relevant features or images, or simplify the visuals"
    },
    {
      icon: Package,
      title: language === 'zh' ? "開始使用" : "Start Using",
      description: language === 'zh' ? "保持簡短易記，讓使用體驗更順暢" : "Keep these short and sweet, so they're easy to remember"
    }
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 px-4 py-3">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 bg-yellow-400 rounded-lg flex items-center justify-center">
              <Zap className="w-5 h-5 text-gray-800" />
            </div>
            <h1 className="text-xl font-bold text-gray-900">Echo Alert</h1>
          </div>
          
          <div className="flex items-center space-x-4">
            <div className="flex bg-gray-100 rounded-lg p-1">
              <button
                onClick={() => setLanguage('zh')}
                className={`px-3 py-1 text-sm rounded-md transition-colors ${
                  language === 'zh' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-600'
                }`}
              >
                中文
              </button>
              <button
                onClick={() => setLanguage('en')}
                className={`px-3 py-1 text-sm rounded-md transition-colors ${
                  language === 'en' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-600'
                }`}
              >
                EN
              </button>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-6xl mx-auto px-4 py-8">
        {/* Hero Section */}
        <div className="text-center mb-16">
          <Badge className="bg-yellow-100 text-yellow-800 border-yellow-200 mb-6">
            {t('badge')}
          </Badge>
          <h1 className="text-4xl md:text-5xl font-bold text-gray-900 mb-6">
            {t('title')}
          </h1>
          <p className="text-xl text-gray-600 mb-8 max-w-2xl mx-auto">
            {t('subtitle')}
          </p>
          <Button 
            onClick={handleStartApp}
            size="lg"
            className="bg-yellow-400 hover:bg-yellow-500 text-gray-900 font-semibold px-8 py-3 text-lg"
          >
            {t('cta')}
          </Button>
        </div>

        {/* How it Works Section */}
        <div className="bg-white rounded-2xl p-8 md:p-12 shadow-sm border border-gray-100">
          <div className="text-center mb-12">
            <p className="text-sm font-medium text-gray-500 uppercase tracking-wide mb-2">
              {language === 'zh' ? "如何運作" : "HOW IT WORKS"}
            </p>
            <h2 className="text-3xl md:text-4xl font-bold text-gray-900">
              {language === 'zh' ? "簡單 3 步驟開始使用" : "Here's how it works, in 3 simple steps."}
            </h2>
          </div>

          <div className="grid md:grid-cols-3 gap-8 md:gap-12">
            {steps.map((step, index) => (
              <div key={index} className="text-center">
                <div className="relative mb-6">
                  <div className="w-20 h-20 bg-yellow-400 rounded-2xl mx-auto flex items-center justify-center mb-4">
                    <step.icon className="w-8 h-8 text-gray-800" />
                  </div>
                  <div className="absolute -top-2 -left-2 w-8 h-8 bg-white border-2 border-gray-300 rounded-full flex items-center justify-center">
                    <span className="text-lg font-bold text-gray-700">{index + 1}</span>
                  </div>
                </div>
                <h3 className="text-lg font-semibold text-gray-900 mb-3">
                  {step.title}
                </h3>
                <p className="text-gray-600 leading-relaxed">
                  {step.description}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Features Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 mt-16">
          <Card className="border-0 shadow-sm bg-white hover:shadow-md transition-shadow">
            <CardContent className="p-6">
              <div className="w-12 h-12 bg-yellow-100 rounded-xl flex items-center justify-center mb-4">
                <Smartphone className="w-6 h-6 text-yellow-600" />
              </div>
              <h3 className="font-semibold text-gray-900 mb-2">{t('cross_platform')}</h3>
              <p className="text-gray-600 text-sm">{t('cross_platform_desc')}</p>
            </CardContent>
          </Card>

          <Card className="border-0 shadow-sm bg-white hover:shadow-md transition-shadow">
            <CardContent className="p-6">
              <div className="w-12 h-12 bg-yellow-100 rounded-xl flex items-center justify-center mb-4">
                <Users className="w-6 h-6 text-yellow-600" />
              </div>
              <h3 className="font-semibold text-gray-900 mb-2">{t('group_comm')}</h3>
              <p className="text-gray-600 text-sm">{t('group_comm_desc')}</p>
            </CardContent>
          </Card>

          <Card className="border-0 shadow-sm bg-white hover:shadow-md transition-shadow md:col-span-2 lg:col-span-1">
            <CardContent className="p-6">
              <div className="w-12 h-12 bg-yellow-100 rounded-xl flex items-center justify-center mb-4">
                <Zap className="w-6 h-6 text-yellow-600" />
              </div>
              <h3 className="font-semibold text-gray-900 mb-2">{t('real_time')}</h3>
              <p className="text-gray-600 text-sm">{t('real_time_desc')}</p>
            </CardContent>
          </Card>
        </div>

        {/* Footer */}
        <footer className="mt-16 pt-8 border-t border-gray-200">
          <div className="flex flex-col md:flex-row justify-between items-center text-sm text-gray-500">
            <div className="flex items-center space-x-4 mb-4 md:mb-0">
              <span className="bg-gray-800 text-white px-2 py-1 rounded text-xs font-medium">
                COMPANY NAME
              </span>
              <span className="bg-gray-200 text-gray-700 px-2 py-1 rounded text-xs">
                CONFIDENTIAL
              </span>
            </div>
            <div className="flex space-x-6">
              <a href="/privacy" className="hover:text-gray-700">{t('privacy')}</a>
              <a href="/terms" className="hover:text-gray-700">{t('terms')}</a>
              <a href="/help" className="hover:text-gray-700">{t('help')}</a>
            </div>
          </div>
        </footer>
      </div>
    </div>
  );
};

export default Index;
