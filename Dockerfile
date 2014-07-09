FROM phusion/baseimage:0.9.11

MAINTAINER mail@agrafix.net

ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

RUN apt-get update
RUN apt-get install -y subversion git python python-pip nginx

# SETUP  RIETVELD
RUN mkdir -p /apps/rietveld
WORKDIR /apps/rietveld

RUN git clone https://github.com/django/django
RUN cd django && git checkout tags/1.2.5
RUN pip install -e django

RUN svn co http://django-gae2django.googlecode.com/svn/trunk/examples/rietveld .
RUN svn co http://django-gae2django.googlecode.com/svn/trunk/gae2django
RUN svn co http://rietveld.googlecode.com/svn/trunk/codereview
RUN svn co http://rietveld.googlecode.com/svn/trunk/static
RUN svn co http://rietveld.googlecode.com/svn/trunk/templates
RUN svn export http://rietveld.googlecode.com/svn/trunk/upload.py
RUN patch -p0 < patches/upload.diff
RUN patch -p0 < patches/account-login-links.diff
RUN patch -p0 < patches/download.link.diff

ADD rietveld/models.diff /apps/rietveld/patches/models.diff
RUN patch codereview/models.py < patches/models.diff

RUN ./manage.py syncdb --noinput
RUN echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'mail@agrafix.net', '75317531')" | ./manage.py shell

RUN mkdir /etc/service/rietveld
ADD rietveld/run.sh /etc/service/rietveld/run

RUN pip install flup

# CONFIGURE NGINX
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
ADD nginx/default.conf /etc/nginx/sites-available/default

RUN mkdir /etc/service/nginx
RUN echo "#!/bin/bash\nnginx" >> /etc/service/nginx/run

EXPOSE 8080

# RUN SYSTEM
RUN chmod -R +x /etc/service
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
CMD ["/sbin/my_init"]