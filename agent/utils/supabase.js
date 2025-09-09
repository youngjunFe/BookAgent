import { createClient } from '@supabase/supabase-js';

// Supabase 설정
const supabaseUrl = process.env.SUPABASE_URL || 'https://bssiddbhnuguloktqsmy.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJzc2lkZGJobnVndWxva3Rxc215Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjMwODM4MDQsImV4cCI6MjAzODY1OTgwNH0.Zt8c_TqAzPuGNF4QHpOzDNgfAaXQJO3Uo8bAKbPXCkM';

export const supabase = createClient(supabaseUrl, supabaseKey);

// 설정값 가져오기
export async function getConfig(key) {
  try {
    const { data, error } = await supabase
      .from('admin_configs')
      .select('config_value')
      .eq('config_key', key)
      .eq('is_active', true)
      .single();

    if (error) {
      console.log(`❌ 설정 로드 실패 (${key}):`, error.message);
      return null;
    }

    console.log(`✅ 설정 로드 성공 (${key}): ${data.config_value?.substring(0, 50)}...`);
    return data.config_value;
  } catch (e) {
    console.log(`❌ 설정 로드 에러 (${key}):`, e.message);
    return null;
  }
}

// 여러 설정값 한번에 가져오기
export async function getConfigs(keys) {
  try {
    const { data, error } = await supabase
      .from('admin_configs')
      .select('config_key, config_value')
      .in('config_key', keys)
      .eq('is_active', true);

    if (error) {
      console.log('❌ 설정 로드 실패:', error.message);
      return {};
    }

    const configs = {};
    data.forEach(row => {
      configs[row.config_key] = row.config_value;
    });

    console.log('✅ 설정 로드 성공:', Object.keys(configs));
    return configs;
  } catch (e) {
    console.log('❌ 설정 로드 에러:', e.message);
    return {};
  }
}

// 기본값과 함께 설정값 가져오기
export async function getConfigWithDefault(key, defaultValue) {
  const value = await getConfig(key);
  return value || defaultValue;
}
