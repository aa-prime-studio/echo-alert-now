import React from 'react';
import { Hash, Target, Calendar } from 'lucide-react';

export const GameRules: React.FC = () => {
  return (
    <div className="bg-gradient-to-br from-blue-50 to-purple-50 border border-blue-200 rounded-xl p-4">
      <div className="flex items-center space-x-2 mb-4">
        <h4 className="text-base font-semibold text-gray-900">遊戲規則</h4>
      </div>
      <div className="grid grid-cols-3 gap-3">
        <div className="bg-white rounded-lg p-3 text-center shadow-sm">
          <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-2">
            <Hash className="w-5 h-5 text-blue-600" />
          </div>
          <p className="text-sm font-medium text-gray-900 mb-1">號碼範圍</p>
          <p className="text-xs text-gray-600">1-60 隨機抽取</p>
        </div>
        
        <div className="bg-white rounded-lg p-3 text-center shadow-sm">
          <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-2">
            <Target className="w-5 h-5 text-green-600" />
          </div>
          <p className="text-sm font-medium text-gray-900 mb-1">獲勝條件</p>
          <p className="text-xs text-gray-600">完成 6 條線即可獲勝</p>
        </div>
        
        <div className="bg-white rounded-lg p-3 text-center shadow-sm">
          <div className="w-10 h-10 bg-yellow-100 rounded-full flex items-center justify-center mx-auto mb-2">
            <Calendar className="w-5 h-5 text-yellow-600" />
          </div>
          <p className="text-sm font-medium text-gray-900 mb-1">每日排行</p>
          <p className="text-xs text-gray-600">每天更新排行榜</p>
        </div>
      </div>
    </div>
  );
};
