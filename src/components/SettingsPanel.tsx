
import React from 'react';
import { Settings, User, Bell, Shield, Trash2, Info, UserX } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog';

interface SettingsPanelProps {
  deviceName: string;
  setDeviceName: (name: string) => void;
  onClearMessages: () => void;
}

export const SettingsPanel: React.FC<SettingsPanelProps> = ({
  deviceName,
  setDeviceName,
  onClearMessages
}) => {
  const [notifications, setNotifications] = React.useState(true);
  const [autoConnect, setAutoConnect] = React.useState(true);
  const [shareLocation, setShareLocation] = React.useState(false);

  const handleDeleteAccount = () => {
    // 這裡可以添加刪除帳號的邏輯
    console.log('刪除帳號');
  };

  return (
    <div className="bg-white rounded-lg shadow">
      <div className="p-4 border-b">
        <div className="flex items-center space-x-2">
          <Settings className="w-5 h-5 text-gray-600" />
          <h3 className="font-semibold text-gray-900">設定</h3>
        </div>
      </div>
      
      <div className="p-4 space-y-6">
        {/* 裝置設定 */}
        <div>
          <div className="flex items-center space-x-2 mb-3">
            <User className="w-4 h-4 text-gray-600" />
            <h4 className="text-sm font-medium text-gray-900">裝置設定</h4>
          </div>
          <div className="space-y-3">
            <div>
              <Label htmlFor="device-name" className="text-sm text-gray-700">
                裝置名稱
              </Label>
              <Input
                id="device-name"
                value={deviceName}
                onChange={(e) => setDeviceName(e.target.value)}
                className="mt-1"
                maxLength={16}
                placeholder="輸入裝置名稱..."
              />
            </div>
          </div>
        </div>

        {/* 通知設定 */}
        <div>
          <div className="flex items-center space-x-2 mb-3">
            <Bell className="w-4 h-4 text-gray-600" />
            <h4 className="text-sm font-medium text-gray-900">通知設定</h4>
          </div>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <Label htmlFor="notifications" className="text-sm text-gray-700">
                推播通知
              </Label>
              <Switch
                id="notifications"
                checked={notifications}
                onCheckedChange={setNotifications}
              />
            </div>
          </div>
        </div>

        {/* 連線設定 */}
        <div>
          <div className="flex items-center space-x-2 mb-3">
            <Shield className="w-4 h-4 text-gray-600" />
            <h4 className="text-sm font-medium text-gray-900">隱私與連線</h4>
          </div>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <div>
                <Label htmlFor="auto-connect" className="text-sm text-gray-700">
                  自動連線
                </Label>
                <p className="text-xs text-gray-500 mt-1">
                  開啟時會自動搜尋並連接附近的裝置
                </p>
              </div>
              <Switch
                id="auto-connect"
                checked={autoConnect}
                onCheckedChange={setAutoConnect}
              />
            </div>
            <div className="flex items-center justify-between">
              <div>
                <Label htmlFor="share-location" className="text-sm text-gray-700">
                  分享位置方向
                </Label>
                <p className="text-xs text-gray-500 mt-1">
                  允許他人看到你的模糊距離和方向
                </p>
              </div>
              <Switch
                id="share-location"
                checked={shareLocation}
                onCheckedChange={setShareLocation}
              />
            </div>
          </div>
        </div>

        {/* 資料管理 */}
        <div>
          <div className="flex items-center space-x-2 mb-3">
            <Trash2 className="w-4 h-4 text-gray-600" />
            <h4 className="text-sm font-medium text-gray-900">資料管理</h4>
          </div>
          <div className="space-y-3">
            <Button
              variant="outline"
              onClick={onClearMessages}
              className="w-full text-red-600 hover:text-red-700 hover:bg-red-50"
            >
              <Trash2 className="w-4 h-4 mr-2" />
              清除所有訊息
            </Button>
            
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button
                  variant="outline"
                  className="w-full text-red-600 hover:text-red-700 hover:bg-red-50 border-red-200"
                >
                  <UserX className="w-4 h-4 mr-2" />
                  刪除帳號
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>確定要刪除帳號嗎？</AlertDialogTitle>
                  <AlertDialogDescription>
                    此操作無法復原。這將永久刪除您的帳號和所有相關資料。
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel>取消</AlertDialogCancel>
                  <AlertDialogAction 
                    onClick={handleDeleteAccount}
                    className="bg-red-600 hover:bg-red-700"
                  >
                    確定刪除
                  </AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          </div>
        </div>

        {/* 關於 */}
        <div>
          <div className="flex items-center space-x-2 mb-3">
            <Info className="w-4 h-4 text-gray-600" />
            <h4 className="text-sm font-medium text-gray-900">關於</h4>
          </div>
          <div className="text-xs text-gray-500 space-y-1">
            <p>Signal-Lite v1.0.0</p>
            <p>緊急通訊概念驗證</p>
            <p>實際版本將使用 MultipeerConnectivity</p>
          </div>
        </div>
      </div>
    </div>
  );
};
