#Install the container's OS.
FROM python:3.5

RUN mkdir -p /opt/app
# Copy the contents of the current working directory to the hugo-site
# directory. The directory will be created if it doesn't exist.
COPY . /opt/app/
WORKDIR /opt/app/

RUN pip install -r requirements.txt

# The container will listen on port 80 using the TCP protocol.
EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
