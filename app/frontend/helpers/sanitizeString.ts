const sanitizeString = (str: string): string | null => {
  const input = str.replace(/(<([^>]+)>)/ig, '').replaceAll('&amp;','&').replaceAll('&quot;','"').replaceAll('\\u0026quot;','"').replaceAll('\\u0026amp;','&')
  const doc = new DOMParser().parseFromString(input, "text/html");
  return doc.documentElement.textContent;
}

export default sanitizeString;
