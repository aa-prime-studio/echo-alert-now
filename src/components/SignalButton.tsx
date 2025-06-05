
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

  if (size === 'large') {
    // Large button for "我安全" - adjusted height to align bottom edge with small buttons (3 * 36px + 2 * 12px gap = 132px)
    return (
      <Button
        onClick={() => onSend(type)}
        disabled={disabled}
        className={`h-[132px] w-full ${config.bgColor} ${config.color} flex flex-col items-center justify-center font-semibold transition-all duration-200 transform active:scale-95 rounded-xl border-0`}
      >
        <Icon className="w-8 h-8 mb-2" />
        <div className="text-center">
          <div className="text-xs font-medium leading-tight">{config.label}</div>
          <div className="text-[10px] opacity-90 leading-tight">{config.description}</div>
        </div>
      </Button>
    );
  } else {
    // Small buttons - horizontal layout with icon on left, text centered
    return (
      <Button
        onClick={() => onSend(type)}
        disabled={disabled}
        className={`h-[36px] w-full ${config.bgColor} ${config.color} flex items-center justify-center px-3 font-semibold transition-all duration-200 transform active:scale-95 rounded-xl border-0`}
      >
        <Icon className="w-4 h-4 mr-2 flex-shrink-0" />
        <div className="text-xs font-medium">{config.label}</div>
      </Button>
    );
  }
};
