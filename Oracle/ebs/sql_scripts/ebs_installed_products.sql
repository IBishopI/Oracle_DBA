-- Found all installed products: 
--------------------------------
select a.application_short_name,a.APPLICATION_NAME,decode(fpi.status,'I','Installed','S','Shared','N','Inactive',fpi.status) status
from apps.fnd_application_vl a, apps.fnd_product_installations fpi where 
fpi.application_id = a.application_id and fpi.status in ('I','S') order by 3,1;