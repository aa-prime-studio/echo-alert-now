import React from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Button } from '@/components/ui/button';

const LanguageTest: React.FC = () => {
  const { language, setLanguage, t } = useLanguage();

  return (
    <div className="p-6 max-w-md mx-auto">
      <h1 className="text-2xl font-bold mb-4">Language Test</h1>
      
      <div className="mb-4">
        <p>Current Language: {language}</p>
        <Button 
          onClick={() => setLanguage(language === 'zh' ? 'en' : 'zh')}
          className="mr-2"
        >
          Switch to {language === 'zh' ? 'English' : '繁體中文'}
        </Button>
      </div>
      
      <div className="space-y-2">
        <h2 className="text-lg font-semibold">Translation Test:</h2>
        <p>Settings: {t('settings')}</p>
        <p>Language: {t('language')}</p>
        <p>Signals: {t('signals')}</p>
        <p>Chat: {t('chat')}</p>
        <p>Games: {t('games')}</p>
        <p>Signal Safe: {t('signal_safe')}</p>
        <p>Signal Supplies: {t('signal_supplies')}</p>
        <p>Signal Medical: {t('signal_medical')}</p>
        <p>Signal Danger: {t('signal_danger')}</p>
        <p>Connected Status: {t('connected_status')}</p>
        <p>No Messages: {t('no_messages')}</p>
        <p>Broadcast Signal: {t('broadcast_signal')}</p>
        <p>Just Now: {t('just_now')}</p>
        <p>Minutes Ago: 5{t('minutes_ago')}</p>
        <p>Hours Ago: 2{t('hours_ago')}</p>
      </div>
      
      <div className="mt-6">
        <h3 className="font-semibold">Hardcoded (should remain the same):</h3>
        <p>Bingo Game Room: Bingo Game Room</p>
      </div>
    </div>
  );
};

export default LanguageTest; 