import React from 'react';
import { Settings, User, Bell, Shield, Trash2, Info, UserX, Edit3, CreditCard, Crown, Star } from 'lucide-react';
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
  const [nameChangeCount, setNameChangeCount] = React.useState(0);
  const [tempDeviceName, setTempDeviceName] = React.useState(deviceName);
  const [isEditing, setIsEditing] = React.useState(false);

  // 模擬付費狀態（實際應從全域狀態或 API 獲取）
  const [isPremium, setIsPremium] = React.useState(false);
  const [subscriptionStatus, setSubscriptionStatus] = React.useState<'free' | 'premium' | 'expired'>('free');

  const maxNameChanges = 1;
  const canChangeName = nameChangeCount < maxNameChanges;

  const handleNameSave = () => {
    if (!canChangeName) return;
    
    setDeviceName(tempDeviceName);
    setNameChangeCount(prev => prev + 1);
    setIsEditing(false);
  };

  const handleNameCancel = () => {
    setTempDeviceName(deviceName);
    setIsEditing(false);
  };

  const handleDeleteAccount = () => {
    console.log('刪除帳號');
  };

  const handleUpgrade = () => {
    console.log('升級到付費版');
    // 這裡會觸發內購或付費流程
  };

  const handleManageSubscription = () => {
    console.log('管理訂購');
    // 開啟訂購管理頁面
  };

  const handleRestorePurchases = () => {
    console.log('恢復購買');
    // iOS 內購恢復功能
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
        {/* 訂購狀態 */}
        <div>
          <div className="flex items-center space-x-2 mb-3">
            <Crown className="w-4 h-4 text-yellow-600" />
            <h4 className="text-sm font-medium text-gray-900">訂購狀態</h4>
          </div>
          <div className="space-y-3">
            <div className={`p-3 rounded-lg border-2 ${
              isPremium ? 'border-yellow-300 bg-yellow-50' : 'border-gray-200 bg-gray-50'
            }`}>
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center space-x-2">
                  {isPremium ? (
                    <Star className="w-5 h-5 text-yellow-500" />
                  ) : (
                    <User className="w-5 h-5 text-gray-500" />
                  )}
                  <span className="font-medium">
                    {isPremium ? '付費版用戶' : '免費版用戶'}
                  </span>
                </div>
                {isPremium && (
                  <span className="text-xs bg-yellow-200 text-yellow-800 px-2 py-1 rounded-full">
                    已解鎖
                  </span>
                )}
              </div>
              <p className="text-sm text-gray-600">
                {isPremium 
                  ? '您已解鎖所有遊戲功能，感謝您的支持！' 
                  : '升級解鎖遊戲功能，享受完整體驗'
                }
              </p>
            </div>

            {!isPremium && (
              <Button
                onClick={handleUpgrade}
                className="w-full bg-yellow-600 hover:bg-yellow-700 text-white"
              >
                <Crown className="w-4 h-4 mr-2" />
                升級解鎖遊戲功能
              </Button>
            )}

            {isPremium && (
              <div className="grid grid-cols-2 gap-2">
                <Button
                  variant="outline"
                  onClick={handleManageSubscription}
                  className="text-sm"
                >
                  <CreditCard className="w-4 h-4 mr-1" />
                  管理訂購
                </Button>
                <Button
                  variant="outline"
                  onClick={handleRestorePurchases}
                  className="text-sm"
                >
                  恢復購買
                </Button>
              </div>
            )}
          </div>
        </div>

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
              <div className="mt-1 flex space-x-2">
                {isEditing ? (
                  <>
                    <Input
                      id="device-name"
                      value={tempDeviceName}
                      onChange={(e) => setTempDeviceName(e.target.value)}
                      className="flex-1"
                      maxLength={16}
                      placeholder="輸入裝置名稱..."
                    />
                    <Button
                      size="sm"
                      onClick={handleNameSave}
                      disabled={!tempDeviceName.trim()}
                      className="bg-green-600 hover:bg-green-700"
                    >
                      保存
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={handleNameCancel}
                    >
                      取消
                    </Button>
                  </>
                ) : (
                  <>
                    <Input
                      value={deviceName}
                      readOnly
                      className="flex-1 bg-gray-50"
                    />
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => setIsEditing(true)}
                      disabled={!canChangeName}
                      className={!canChangeName ? 'opacity-50 cursor-not-allowed' : ''}
                    >
                      <Edit3 className="w-4 h-4" />
                    </Button>
                  </>
                )}
              </div>
              <div className="mt-2 text-xs text-gray-500">
                {canChangeName ? (
                  <span>可修改 1 次</span>
                ) : (
                  <span className="text-red-500">名稱已確定，無法再修改</span>
                )}
              </div>
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
