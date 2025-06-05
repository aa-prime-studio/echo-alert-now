
import React from 'react';
import { Hash, Target, Calendar } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';

export const GameRules: React.FC = () => {
  return (
    <Card className="bg-white border-black shadow-sm">
      <CardContent className="p-6">
        <h4 className="text-lg font-semibold text-gray-900 mb-4">遊戲規則</h4>
        <div className="grid grid-cols-3 gap-4">
          <div className="text-center">
            <div className="w-12 h-12 rounded-full flex items-center justify-center mx-auto mb-3" style={{ backgroundColor: '#00d76a' }}>
              <Hash className="w-6 h-6 text-white" />
            </div>
            <p className="text-sm font-medium text-gray-900 mb-1">號碼範圍</p>
            <p className="text-xs text-gray-600">1-60 隨機抽取</p>
          </div>
          
          <div className="text-center">
            <div className="w-12 h-12 rounded-full flex items-center justify-center mx-auto mb-3" style={{ backgroundColor: '#00d76a' }}>
              <Target className="w-6 h-6 text-white" />
            </div>
            <p className="text-sm font-medium text-gray-900 mb-1">獲勝條件</p>
            <p className="text-xs text-gray-600">完成 6 條線即可獲勝</p>
          </div>
          
          <div className="text-center">
            <div className="w-12 h-12 rounded-full flex items-center justify-center mx-auto mb-3" style={{ backgroundColor: '#00d76a' }}>
              <Calendar className="w-6 h-6 text-white" />
            </div>
            <p className="text-sm font-medium text-gray-900 mb-1">每日排行</p>
            <p className="text-xs text-gray-600">每天更新排行榜</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};
