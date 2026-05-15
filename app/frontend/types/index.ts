export interface Story {
  title: string;
  link: string;
  source: string;
  media_url?: string;
  media_url_thumb?: string;
  content?: string | string[];
  description?: string;
}

export interface NewsSourceData {
  source_name: string;
  source_url: string;
  stories: Story[];
  source_id: number;
  enabled: boolean;
  list_order: number;
}
