
import React from 'react';
import { Settings, User, Bell, Shield, Trash2, Info, UserX, Edit3, CreditCard, Crown, Star, HelpCircle, FileText, Languages, Calendar, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useLanguage } from '@/contexts/LanguageContext';
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
  const { language, setLanguage, t } = useLanguage();
  const [notifications, setNotifications] = React.useState(true);
  const [autoConnect, setAutoConnect] = React.useState(true);
  const [shareLocation, setShareLocation] = React.useState(false);
  const [nameChangeCount, setNameChangeCount] = React.useState(0);
  const [tempDeviceName, setTempDeviceName] = React.useState(deviceName);
  const [isEditing, setIsEditing] = React.useState(false);

  // 模擬付費狀態（實際應從全域狀態或 API 獲取）
  const [isPremium, setIsPremium] = React.useState(false);
  const [subscriptionStatus, setSubscriptionStatus] = React.useState<'free' | 'premium' | 'expired'>('free');
  const [subscriptionEndDate, setSubscriptionEndDate] = React.useState<string>('2024-07-15');

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

  const handleCancelSubscription = () => {
    console.log('取消訂閱');
    // 實際應該呼叫取消訂閱的 API
    setIsPremium(false);
    setSubscriptionStatus('expired');
  };

  const handleRestorePurchases = () => {
    console.log('恢復購買');
    // iOS 內購恢復功能
  };

  const handleViewSubscriptionDetails = () => {
    console.log('查看訂閱詳情');
    // 顯示詳細的訂閱資訊
  };

  return (
    <div className="bg-white rounded-lg shadow border border-gray-200">
      <div className="p-4 border-b border-gray-200">
        <div className="flex items-center space-x-2">
          <Settings className="w-5 h-5 text-gray-600" />
          <h3 className="text-base font-semibold text-gray-900">{t('settings')}</h3>
        </div>
      </div>
      
      <div className="p-4 space-y-6">
        {/* 語言設定 */}
        <div className="border border-gray-200 rounded-lg p-4">
          <div className="flex items-center space-x-2 mb-3">
            <Languages className="w-4 h-4 text-gray-600" />
            <h4 className="text-sm font-medium text-gray-900">{t('language')}</h4>
          </div>
          <Select value={language} onValueChange={(value) => setLanguage(value as 'zh' | 'en')}>
            <SelectTrigger className="w-full border-gray-300">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="zh">{t('chinese')}</SelectItem>
              <SelectItem value="en">{t('english')}</SelectItem>
            </SelectContent>
          </Select>
        </div>

        {/* 訂購狀態 */}
        <div className="border border-gray-200 rounded-lg p-4">
          <div className="flex items-center space-x-2 mb-3">
            <Crown className="w-4 h-4 text-yellow-600" />
            <h4 className="text-sm font-medium text-gray-900">{t('subscription_status')}</h4>
          </div>
          <div className="space-y-3">
            <div className={`p-3 rounded-lg border-2 ${
              isPremium ? 'border-yellow-300 bg-yellow-50' : 'border-gray-300 bg-gray-50'
            }`}>
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center space-x-2">
                  {isPremium ? (
                    <Star className="w-5 h-5 text-yellow-500" />
                  ) : (
                    <User className="w-5 h-5 text-gray-500" />
                  )}
                  <span className="font-medium">
                    {isPremium ? t('premium_user') : t('free_user')}
                  </span>
                </div>
                {isPremium && (
                  <span className="text-xs bg-yellow-200 text-yellow-800 px-2 py-1 rounded-full">
                    {t('unlocked')}
                  </span>
                )}
              </div>
              <p className="text-sm text-gray-600">
                {isPremium 
                  ? t('premium_message')
                  : t('upgrade_message')
                }
              </p>
              {isPremium && (
                <div className="mt-2 flex items-center text-xs text-gray-500">
                  <Calendar className="w-3 h-3 mr-1" />
                  <span>到期日期: {subscriptionEndDate}</span>
                </div>
              )}
            </div>

            {!isPremium && (
              <Button
                onClick={handleUpgrade}
                className="w-full bg-yellow-600 hover:bg-yellow-700 text-white border border-yellow-700"
              >
                <Crown className="w-4 h-4 mr-2" />
                {t('upgrade_unlock_games')}
              </Button>
            )}

            {isPremium && (
              <div className="space-y-2">
                <div className="grid grid-cols-2 gap-2">
                  <Button
                    variant="outline"
                    onClick={handleViewSubscriptionDetails}
                    className="text-sm border-gray-300"
                  >
                    <Info className="w-4 h-4 mr-1" />
                    查看詳情
                  </Button>
                  <Button
                    variant="outline"
                    onClick={handleManageSubscription}
                    className="text-sm border-gray-300"
                  >
                    <CreditCard className="w-4 h-4 mr-1" />
                    {t('manage_subscription')}
                  </Button>
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <Button
                    variant="outline"
                    onClick={handleRestorePurchases}
                    className="text-sm border-gray-300"
                  >
                    恢復購買
                  </Button>
                  <AlertDialog>
                    <AlertDialogTrigger asChild>
                      <Button
                        variant="outline"
                        className="text-sm text-red-600 hover:text-red-700 hover:bg-red-50 border-red-300"
                      >
                        <X className="w-4 h-4 mr-1" />
                        取消訂閱
                      </Button>
                    </AlertDialogTrigger>
                    <AlertDialogContent>
                      <AlertDialogHeader>
                        <AlertDialogTitle>確定要取消訂閱嗎？</AlertDialogTitle>
                        <AlertDialogDescription>
                          取消後您將失去所有付費功能的存取權限。您可以繼續使用到訂閱期結束 ({subscriptionEndDate})。
                        </AlertDialogDescription>
                      </AlertDialogHeader>
                      <AlertDialogFooter>
                        <AlertDialogCancel>保留訂閱</AlertDialogCancel>
                        <AlertDialogAction 
                          onClick={handleCancelSubscription}
                          className="bg-red-600 hover:bg-red-700"
                        >
                          確定取消
                        </AlertDialogAction>
                      </AlertDialogFooter>
                    </AlertDialogContent>
                  </AlertDialog>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* 裝置設定 */}
        <div className="border border-gray-200 rounded-lg p-4">
          <div className="flex items-center space-x-2 mb-3">
            <User className="w-4 h-4 text-gray-600" />
            <h4 className="text-sm font-medium text-gray-900">{t('device_settings')}</h4>
          </div>
          
          <div className="space-y-3">
            <div>
              <Label htmlFor="device-name" className="text-sm text-gray-700">
                {t('device_name')}
              </Label>
              <div className="mt-1 flex space-x-2">
                {isEditing ? (
                  <>
                    <Input
                      id="device-name"
                      value={tempDeviceName}
                      onChange={(e) => setTempDeviceName(e.target.value)}
                      className="flex-1 border-gray-300"
                      maxLength={16}
                      placeholder="輸入裝置名稱..."
                    />
                    <Button
                      size="sm"
                      onClick={handleNameSave}
                      disabled={!tempDeviceName.trim()}
                      className="bg-green-600 hover:bg-green-700 border border-green-700"
                    >
                      {t('save')}
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={handleNameCancel}
                      className="border-gray-300"
                    >
                      {t('cancel')}
                    </Button>
                  </>
                ) : (
                  <>
                    <Input
                      value={deviceName}
                      readOnly
                      className="flex-1 bg-gray-50 border-gray-300"
                    />
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => setIsEditing(true)}
                      disabled={!canChangeName}
                      className={`border-gray-300 ${!canChangeName ? 'opacity-50 cursor-not-allowed' : ''}`}
                    >
                      <Edit3 className="w-4 h-4" />
                    </Button>
                  </>
                )}
              </div>
              <div className="mt-2 text-xs text-gray-500">
                {canChangeName ? (
                  <span>{t('can_change_once')}</span>
                ) : (
                  <span className="text-red-500">{t('name_fixed')}</span>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* 通知設定 */}
        <div className="border border-gray-200 rounded-lg p-4">
          <div className="flex items-center space-x-2 mb-3">
            <Bell className="w-4 h-4 text-gray-600" />
            <h4 className="text-sm font-medium text-gray-900">{t('notification_settings')}</h4>
          </div>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <Label htmlFor="notifications" className="text-sm text-gray-700">
                {t('push_notifications')}
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
        <div className="border border-gray-200 rounded-lg p-4">
          <div className="flex items-center space-x-2 mb-3">
            <Shield className="w-4 h-4 text-gray-600" />
            <h4 className="text-sm font-medium text-gray-900">{t('privacy_connection')}</h4>
          </div>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <div>
                <Label htmlFor="auto-connect" className="text-sm text-gray-700">
                  {t('auto_connect')}
                </Label>
                <p className="text-xs text-gray-500 mt-1">
                  {t('auto_connect_desc')}
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
                  {t('share_location')}
                </Label>
                <p className="text-xs text-gray-500 mt-1">
                  {t('share_location_desc')}
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
        <div className="border border-gray-200 rounded-lg p-4">
          <div className="flex items-center space-x-2 mb-3">
            <Trash2 className="w-4 h-4 text-gray-600" />
            <h4 className="text-sm font-medium text-gray-900">{t('data_management')}</h4>
          </div>
          <div className="space-y-3">
            <Button
              variant="outline"
              onClick={onClearMessages}
              className="w-full text-red-600 hover:text-red-700 hover:bg-red-50 border-red-300"
            >
              <Trash2 className="w-4 h-4 mr-2" />
              {t('clear_all_messages')}
            </Button>
            
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button
                  variant="outline"
                  className="w-full text-red-600 hover:text-red-700 hover:bg-red-50 border-red-300"
                >
                  <UserX className="w-4 h-4 mr-2" />
                  {t('delete_account')}
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>{t('confirm_delete_title')}</AlertDialogTitle>
                  <AlertDialogDescription>
                    {t('confirm_delete_desc')}
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel>取消</AlertDialogCancel>
                  <AlertDialogAction 
                    onClick={handleDeleteAccount}
                    className="bg-red-600 hover:bg-red-700"
                  >
                    {t('confirm_delete')}
                  </AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          </div>
        </div>

        {/* 法律文件連結 */}
        <div className="border border-gray-200 rounded-lg p-4">
          <div className="flex items-center space-x-2 mb-3">
            <Info className="w-4 h-4 text-gray-600" />
            <h4 className="text-sm font-medium text-gray-900">{t('legal_help')}</h4>
          </div>
          <div className="space-y-2">
            <Button
              variant="ghost"
              className="w-full justify-start text-left text-gray-600 hover:text-gray-900 hover:bg-gray-100 border border-transparent hover:border-gray-200"
              onClick={() => window.open('/help', '_blank')}
            >
              <HelpCircle className="w-4 h-4 mr-2" />
              {t('help_guide')}
            </Button>
            <Button
              variant="ghost" 
              className="w-full justify-start text-left text-gray-600 hover:text-gray-900 hover:bg-gray-100 border border-transparent hover:border-gray-200"
              onClick={() => window.open('/privacy', '_blank')}
            >
              <Shield className="w-4 h-4 mr-2" />
              {t('privacy_policy')}
            </Button>
            <Button
              variant="ghost"
              className="w-full justify-start text-left text-gray-600 hover:text-gray-900 hover:bg-gray-100 border border-transparent hover:border-gray-200" 
              onClick={() => window.open('/terms', '_blank')}
            >
              <FileText className="w-4 h-4 mr-2" />
              {t('terms_service')}
            </Button>
          </div>
        </div>

        {/* 關於 */}
        <div className="border border-gray-200 rounded-lg p-4">
          <div className="flex items-center space-x-2 mb-3">
            <Info className="w-4 h-4 text-gray-600" />
            <h4 className="text-sm font-medium text-gray-900">{t('about')}</h4>
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
