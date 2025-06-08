import React from 'react';
import { Hash, Target, Calendar } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { useLanguage } from '@/contexts/LanguageContext';

export const GameRules: React.FC = () => {
  const { t } = useLanguage();
  
  return (
    <Card className="bg-white border-black shadow-sm">
      <CardContent className="p-6">
        <h4 className="text-base font-semibold text-gray-900 mb-4 text-left">
          {t('game_rules')}
        </h4>
        <div className="grid grid-cols-3 gap-4">
          <div className="text-left">
            <div className="w-12 h-12 rounded-full flex items-center justify-center mb-3 border border-black" style={{ backgroundColor: '#00d76a' }}>
              <Hash className="w-6 h-6" style={{ color: '#263ee4' }} />
            </div>
            <p style={{ fontSize: '1rem' }} className="font-semibold text-gray-900 mb-1">
              {t('number_range')}
            </p>
            <p className="text-sm text-gray-600">{t('number_range_desc')}</p>
          </div>
          
          <div className="text-left">
            <div className="w-12 h-12 rounded-full flex items-center justify-center mb-3 border border-black" style={{ backgroundColor: '#00d76a' }}>
              <Target className="w-6 h-6" style={{ color: '#263ee4' }} />
            </div>
            <p style={{ fontSize: '1rem' }} className="font-semibold text-gray-900 mb-1">
              {t('win_condition')}
            </p>
            <p className="text-sm text-gray-600">{t('win_condition_desc')}</p>
          </div>
          
          <div className="text-left">
            <div className="w-12 h-12 rounded-full flex items-center justify-center mb-3 border border-black" style={{ backgroundColor: '#00d76a' }}>
              <Calendar className="w-6 h-6" style={{ color: '#263ee4' }} />
            </div>
            <p style={{ fontSize: '1rem' }} className="font-semibold text-gray-900 mb-1">
              {t('daily_ranking')}
            </p>
            <p className="text-sm text-gray-600">{t('daily_ranking_desc')}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};
