
import React from 'react';
import { AlertTriangle, Heart, Package, Shield } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface SignalButtonProps {
  type: 'safe' | 'supplies' | 'medical' | 'danger';
  onSend: (type: 'safe' | 'supplies' | 'medical' | 'danger') => void;
  disabled?: boolean;
  size?: 'large' | 'small';
}

const signalConfig = {
  safe: {
    label: '我安全',
    description: 'I\'m Safe',
    color: 'text-white',
    bgColor: 'bg-[#263eea] hover:bg-[#1d32d4]',
    icon: Shield
  },
  supplies: {
    label: '需要物資',
    description: 'Need Supplies',
    color: 'text-white',
    bgColor: 'bg-[#b199ea] hover:bg-[#a085e6]',
    icon: Package
  },
  medical: {
    label: '需要醫療',
    description: 'Need Medical',
    color: 'text-white',
    bgColor: 'bg-[#ff5662] hover:bg-[#ff4553]',
    icon: Heart
  },
  danger: {
    label: '危險警告',
    description: 'Danger Warning',
    color: 'text-black',
    bgColor: 'bg-[#fec91b] hover:bg-[#fdc107]',
    icon: AlertTriangle
  }
};

export const SignalButton: React.FC<SignalButtonProps> = ({ type, onSend, disabled, size = 'large' }) => {
  const config = signalConfig[type];
  const Icon = config.icon;

  const sizeClasses = size === 'large' 
    ? 'h-16 text-base space-y-2' 
    : 'h-12 text-sm space-y-1';
    
  const iconSize = size === 'large' ? 'w-7 h-7' : 'w-5 h-5';
  const textSize = size === 'large' ? 'text-sm' : 'text-xs';
  const descSize = size === 'large' ? 'text-xs' : 'text-[10px]';

  return (
    <Button
      onClick={() => onSend(type)}
      disabled={disabled}
      className={`${sizeClasses} w-full ${config.bgColor} ${config.color} flex flex-col items-center justify-center font-semibold transition-all duration-200 transform active:scale-95 rounded-xl border-0`}
    >
      <Icon className={iconSize} />
      <div className="text-center leading-tight">
        <div className={`${textSize} leading-tight`}>{config.label}</div>
        {size === 'large' && (
          <div className={`${descSize} opacity-80 leading-tight`}>{config.description}</div>
        )}
      </div>
    </Button>
  );
};
